import Foundation

#if os(iOS) || os(watchOS)
import HealthKit

final class HealthKitWriter {
    enum HealthError: LocalizedError {
        case unavailable
        case writeAccessDenied

        var errorDescription: String? {
            switch self {
            case .unavailable:
                "Health access is not available on this device."
            case .writeAccessDenied:
                "Mindful Minutes access was not allowed. You can change this in the Health app."
            }
        }
    }

    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestWriteAuthorization() async throws {
        guard isAvailable,
              let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            throw HealthError.unavailable
        }
        try await store.requestAuthorization(toShare: [mindfulType], read: [])
        guard store.authorizationStatus(for: mindfulType) == .sharingAuthorized else {
            throw HealthError.writeAccessDenied
        }
    }

    var hasWriteAuthorization: Bool {
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            return false
        }
        return store.authorizationStatus(for: mindfulType) == .sharingAuthorized
    }

    func saveMindfulSession(_ record: MeditationRecord) async throws {
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            throw HealthError.unavailable
        }
        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: record.meditationStartedAt,
            end: record.endedAt,
            metadata: [
                HKMetadataKeySyncIdentifier: record.id.uuidString,
                HKMetadataKeySyncVersion: 1
            ]
        )
        try await store.save(sample)
    }
}
#else
final class HealthKitWriter {
    var isAvailable: Bool { false }
    var hasWriteAuthorization: Bool { false }
    func requestWriteAuthorization() async throws {}
    func saveMindfulSession(_ record: MeditationRecord) async throws {}
}
#endif
