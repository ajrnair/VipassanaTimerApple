import Foundation
import Testing
#if SWIFT_PACKAGE
@testable import VipassanaCore
#endif

@Suite("Guide manifest")
struct GuideManifestTests {
    private func loadManifest() throws -> [String: Any] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("audio/v2/cues.json")
        let data = try Data(contentsOf: url)
        let object = try JSONSerialization.jsonObject(with: data)
        return try #require(object as? [String: Any])
    }

    @Test("Manifest timing constants match the timer engine")
    func timelineMatchesEngine() throws {
        let manifest = try loadManifest()
        let timeline = try #require(manifest["timeline"] as? [String: Any])
        let preparation = try #require(timeline["preparationSeconds"] as? NSNumber)
        let warningOffset = try #require(timeline["warningOffsetBeforeEndSeconds"] as? NSNumber)
        let warningThreshold = try #require(
            timeline["warningRequiresDurationStrictlyOverMinutes"] as? NSNumber)

        #expect(preparation.doubleValue == TimerEngine.preparationDuration)
        #expect(warningOffset.doubleValue == TimerEngine.warningOffset)
        #expect(warningThreshold.doubleValue * 60 == TimerEngine.warningMinimumSessionDuration)
    }

    @Test("Every program's closing-bell expectation matches the contract")
    func programWarningRuleMatchesContract() throws {
        // The bell lives only inside the assembled guided audio; the engine
        // schedules nothing mid-sit. The manifest is validated against the
        // contract constants directly.
        let manifest = try loadManifest()
        let programs = try #require(manifest["programs"] as? [[String: Any]])
        #expect(!programs.isEmpty)

        for program in programs {
            let minutes = try #require(program["durationMinutes"] as? NSNumber).intValue
            let manifestWarns = Double(minutes * 60) > TimerEngine.warningMinimumSessionDuration
            let expected = minutes > 30
            #expect(manifestWarns == expected, "duration \(minutes) minutes")
        }
    }
}
