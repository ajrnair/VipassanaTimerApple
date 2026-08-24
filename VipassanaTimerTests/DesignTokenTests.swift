import Foundation
import Testing

@Suite("Design tokens")
struct DesignTokenTests {
    private let repositoryRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    private let watchTokenNames = [
        "AccentColor",
        "VTBackground",
        "VTBorder",
        "VTButtonText",
        "VTMuted",
        "VTPatina",
        "VTSelected",
        "VTSurface",
        "VTText"
    ]

    private let widgetTokenNames = [
        "VTWidgetAccent",
        "VTWidgetBackground",
        "VTWidgetText"
    ]

    @Test("The shared catalog defines every Watch semantic color")
    func sharedCatalogDefinesWatchColors() throws {
        let catalog = repositoryRoot.appendingPathComponent("Shared/BrandColors.xcassets")

        for token in watchTokenNames {
            let contents = catalog
                .appendingPathComponent("\(token).colorset")
                .appendingPathComponent("Contents.json")
            let data = try Data(contentsOf: contents)
            let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
            let colors = try #require(object["colors"] as? [[String: Any]])
            #expect(colors.contains { $0["idiom"] as? String == "watch" })
        }
    }

    @Test("Watch and widget code use semantic colors instead of RGB literals")
    func noInlineProductColors() throws {
        let sourcePaths = [
            "VipassanaTimerWatchApp Watch App/WatchPalette.swift",
            "VipassanaTimerWidgets/VipassanaTimerWidgets.swift"
        ]

        for path in sourcePaths {
            let source = try String(contentsOf: repositoryRoot.appendingPathComponent(path), encoding: .utf8)
            #expect(!source.contains("Color(red:"))
        }
    }

    @Test("The shared catalog defines every widget semantic color")
    func sharedCatalogDefinesWidgetColors() {
        let catalog = repositoryRoot.appendingPathComponent("Shared/BrandColors.xcassets")

        for token in widgetTokenNames {
            let contents = catalog
                .appendingPathComponent("\(token).colorset")
                .appendingPathComponent("Contents.json")
            #expect(FileManager.default.fileExists(atPath: contents.path))
        }
    }

    @Test("The app icon generator consumes the shared catalog")
    func iconGeneratorUsesSemanticColors() throws {
        let source = try String(
            contentsOf: repositoryRoot.appendingPathComponent("scripts/make_app_icons.swift"),
            encoding: .utf8
        )
        #expect(source.contains("Shared/BrandColors.xcassets"))
        #expect(!source.contains("rgb(0x"))
    }
}
