#if os(iOS) || os(watchOS)
import Foundation
@preconcurrency import WatchConnectivity

final class HistorySyncService: NSObject, WCSessionDelegate {
    private let store: HistoryStore
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let onChange: () -> Void
    private var session: WCSession?

    init(store: HistoryStore, onChange: @escaping () -> Void) {
        self.store = store
        self.onChange = onChange
        super.init()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        self.session = session
        session.delegate = self
        session.activate()
    }

    func push() {
        guard let session, session.activationState == .activated,
              let data = try? encoder.encode(store.syncSnapshot()) else { return }
        if session.isReachable {
            session.sendMessageData(data, replyHandler: nil) { [weak session] _ in
                session?.transferUserInfo(["historySnapshot": data])
            }
        } else {
            session.transferUserInfo(["historySnapshot": data])
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated, error == nil else { return }
        push()
    }

    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        receive(messageData)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let data = userInfo["historySnapshot"] as? Data else { return }
        receive(data)
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    private func receive(_ data: Data) {
        guard let snapshot = try? decoder.decode(HistorySyncSnapshot.self, from: data),
              (try? store.merge(snapshot)) == true else { return }
        DispatchQueue.main.async { [onChange] in
            onChange()
        }
        push()
    }
}
#else
final class HistorySyncService {
    init(store: HistoryStore, onChange: @escaping () -> Void) {}
    func activate() {}
    func push() {}
}
#endif
