import Testing

#if SWIFT_PACKAGE
@testable import VipassanaCore
#endif

@Suite("Guided program catalog")
struct GuidanceModeTests {
    @Test("Only the first guided preset set is supported")
    func supportedDurations() {
        #expect(GuidedProgramCatalog.supportedMinutes == [15, 30, 45, 60])
        #expect(GuidedProgramCatalog.supports(minutes: 15))
        #expect(GuidedProgramCatalog.supports(minutes: 60))
        #expect(!GuidedProgramCatalog.supports(minutes: 1))
        #expect(!GuidedProgramCatalog.supports(minutes: 120))
    }

    @Test("Program names match the bundled assets")
    func programNames() {
        #expect(
            GuidedProgramCatalog.fileName(minutes: 30) ==
                "guide-program-guided-30-v2-en"
        )
        #expect(GuidedProgramCatalog.fileName(minutes: 120) == nil)
    }
}
