#!/usr/bin/env swift

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let outputDirectory = URL(
    fileURLWithPath: CommandLine.arguments.dropFirst().first
        ?? "VipassanaTimer/Resources/Assets.xcassets/AppIcon.appiconset",
    isDirectory: true
)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

struct AssetColorSet: Decodable {
    struct Entry: Decodable {
        struct Value: Decodable {
            struct Components: Decodable {
                let red: String
                let green: String
                let blue: String
                let alpha: String
            }

            let components: Components
        }

        struct Appearance: Decodable {
            let appearance: String
            let value: String
        }

        let color: Value?
        let idiom: String
        let appearances: [Appearance]?
    }

    let colors: [Entry]
}

let projectRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
let brandCatalog = projectRoot.appendingPathComponent("Shared/BrandColors.xcassets", isDirectory: true)

/// `appearance == nil` selects the universal entry that carries no `appearances`
/// key (Dawn, the light appearance). `"dark"` selects the entry whose
/// `appearances` names it (Night). The icon is a single static asset, not
/// theme-adaptive, so this is the one place a specific appearance is pinned
/// rather than left to resolve automatically the way `Color("...")` does at
/// runtime.
func brandColor(named name: String, appearance: String? = nil) throws -> CGColor {
    let contentsURL = brandCatalog
        .appendingPathComponent("\(name).colorset", isDirectory: true)
        .appendingPathComponent("Contents.json")
    let colorSet = try JSONDecoder().decode(AssetColorSet.self, from: Data(contentsOf: contentsURL))
    let matches: (AssetColorSet.Entry) -> Bool = { entry in
        guard entry.idiom == "universal", entry.color != nil else { return false }
        if let appearance {
            return entry.appearances?.contains { $0.appearance == "luminosity" && $0.value == appearance } ?? false
        }
        return entry.appearances?.isEmpty ?? true
    }
    guard let entry = colorSet.colors.first(where: matches),
       let components = entry.color?.components,
       let red = Double(components.red),
       let green = Double(components.green),
       let blue = Double(components.blue),
       let alpha = Double(components.alpha) else {
        throw CocoaError(.fileReadCorruptFile)
    }

    func byteAligned(_ component: Double) -> CGFloat {
        CGFloat((component * 255).rounded() / 255)
    }

    // Built in sRGB explicitly. `CGColor(red:green:blue:alpha:)` returns a generic
    // RGB colour, and converting that into this file's sRGB context applies a
    // gamma shift that lifts exactly the near-black tones this field is made of —
    // the catalog's #0A0A1E came out around #0A0C29, visibly wrong at the top of
    // the icon and drifting from the very tokens the catalog exists to fix.
    guard let srgb = CGColorSpace(name: CGColorSpace.sRGB),
          let color = CGColor(
              colorSpace: srgb,
              components: [
                  byteAligned(red),
                  byteAligned(green),
                  byteAligned(blue),
                  byteAligned(alpha)
              ]
          ) else {
        throw CocoaError(.fileWriteUnknown)
    }
    return color
}

func makeContext(side: Int) throws -> CGContext {
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    guard let context = CGContext(
        data: nil,
        width: side,
        height: side,
        bitsPerComponent: 8,
        bytesPerRow: side * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else {
        throw CocoaError(.fileWriteUnknown)
    }
    context.interpolationQuality = .high
    return context
}

func pngData(for image: CGImage) throws -> Data {
    let mutableData = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(
        mutableData,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw CocoaError(.fileWriteUnknown)
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw CocoaError(.fileWriteUnknown)
    }
    return mutableData as Data
}

let masterContext = try makeContext(side: 1024)
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

// The icon is Night, pinned rather than system-adaptive (see brandColor above):
// a still image can't grow the aperture the way a live session does, so it
// shows the field at rest with the ring standing in for the gong, rather than
// picking one arbitrary moment of the animated bloom.
let fieldTop = try brandColor(named: "VTField2", appearance: "dark")
let fieldBottom = try brandColor(named: "VTField5", appearance: "dark")
let ring = try brandColor(named: "AccentColor", appearance: "dark")

guard let fieldGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [fieldTop, fieldBottom] as CFArray,
    locations: [0, 1]
) else {
    throw CocoaError(.fileWriteUnknown)
}
// A bitmap context puts its origin at the bottom-left with y running up, so the
// top of the finished image is y = 1024. Starting at y = 0 would paint the field
// upside down: its lighter violet along the bottom edge and its darkest tone at
// the top, the reverse of the field the app actually opens into.
masterContext.drawLinearGradient(
    fieldGradient,
    start: CGPoint(x: 512, y: 1024),
    end: CGPoint(x: 512, y: 0),
    options: []
)

// One centered hairline, nothing else - the purest statement of the language:
// not a logo of a gong, a glimpse through the aperture.
masterContext.setStrokeColor(ring)
masterContext.setAlpha(0.9)
masterContext.setLineWidth(16)
masterContext.strokeEllipse(in: CGRect(x: 212, y: 212, width: 600, height: 600))
masterContext.setAlpha(1)

guard let masterImage = masterContext.makeImage() else { throw CocoaError(.fileWriteUnknown) }
let masterData = try pngData(for: masterImage)
try masterData.write(
    to: outputDirectory.appendingPathComponent("AppIcon-iOS-1024.png"),
    options: .atomic
)

let macIcons: [(String, Int)] = [
    ("AppIcon-mac-16.png", 16),
    ("AppIcon-mac-32.png", 32),
    ("AppIcon-mac-64.png", 64),
    ("AppIcon-mac-128.png", 128),
    ("AppIcon-mac-256.png", 256),
    ("AppIcon-mac-512.png", 512),
    ("AppIcon-mac-1024.png", 1024)
]

for (name, side) in macIcons {
    let context = try makeContext(side: side)
    context.draw(masterImage, in: CGRect(x: 0, y: 0, width: side, height: side))
    guard let image = context.makeImage() else { throw CocoaError(.fileWriteUnknown) }
    try pngData(for: image).write(
        to: outputDirectory.appendingPathComponent(name),
        options: .atomic
    )
}

print("Created the iOS and macOS app icon set in \(outputDirectory.path)")
