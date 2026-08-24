#!/usr/bin/env swift

import AVFoundation
import Foundation

enum GongAssetError: LocalizedError {
    case usage
    case unreadableAudio

    var errorDescription: String? {
        switch self {
        case .usage:
            return "Usage: make_gong_assets.swift <source-audio> <output-directory>"
        case .unreadableAudio:
            return "The source audio could not be decoded."
        }
    }
}

func writeCAF(
    samples: [Float],
    sampleRate: Double,
    repetitions: Int,
    to destination: URL
) throws {
    guard !samples.isEmpty else { throw GongAssetError.unreadableAudio }

    var data = Data("caff".utf8)
    func appendBigEndian<T: FixedWidthInteger>(_ value: T) {
        var encoded = value.bigEndian
        withUnsafeBytes(of: &encoded) { data.append(contentsOf: $0) }
    }
    func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
        var encoded = value.littleEndian
        withUnsafeBytes(of: &encoded) { data.append(contentsOf: $0) }
    }

    appendBigEndian(UInt16(1))
    appendBigEndian(UInt16(0))
    data.append(contentsOf: Data("desc".utf8))
    appendBigEndian(Int64(32))
    appendBigEndian(sampleRate.bitPattern)
    data.append(contentsOf: Data("lpcm".utf8))
    appendBigEndian(UInt32(14)) // little-endian | signed integer | packed
    appendBigEndian(UInt32(2))
    appendBigEndian(UInt32(1))
    appendBigEndian(UInt32(1))
    appendBigEndian(UInt32(16))

    let sampleCount = samples.count * repetitions
    data.append(contentsOf: Data("data".utf8))
    appendBigEndian(Int64(4 + sampleCount * MemoryLayout<Int16>.size))
    appendBigEndian(UInt32(0))
    for _ in 0..<repetitions {
        for value in samples {
            let normalized = min(1, max(-1, value))
            let sample = Int16(normalized * Float(Int16.max))
            appendLittleEndian(sample)
        }
    }
    try data.write(to: destination, options: .atomic)
}

do {
    guard CommandLine.arguments.count == 3 else { throw GongAssetError.usage }

    let source = URL(fileURLWithPath: CommandLine.arguments[1])
    let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
    try FileManager.default.createDirectory(
        at: outputDirectory,
        withIntermediateDirectories: true
    )

    let input = try AVAudioFile(forReading: source)
    let maximumFrames = AVAudioFrameCount(input.processingFormat.sampleRate * 9)
    guard let buffer = AVAudioPCMBuffer(
        pcmFormat: input.processingFormat,
        frameCapacity: maximumFrames
    ) else {
        throw GongAssetError.unreadableAudio
    }
    try input.read(into: buffer, frameCount: maximumFrames)
    guard buffer.frameLength > 0, let channels = buffer.floatChannelData else {
        throw GongAssetError.unreadableAudio
    }

    let channelCount = Int(buffer.format.channelCount)
    let frameCount = Int(buffer.frameLength)
    var mono = [Float](repeating: 0, count: frameCount)
    for frame in 0..<frameCount {
        var sum: Float = 0
        for channel in 0..<channelCount {
            sum += channels[channel][frame]
        }
        mono[frame] = sum / Float(channelCount)
    }

    let sampleRate = input.processingFormat.sampleRate
    let seconds = Double(frameCount) / sampleRate
    try writeCAF(
        samples: mono,
        sampleRate: sampleRate,
        repetitions: 1,
        to: outputDirectory.appendingPathComponent("gong_start.caf")
    )
    try writeCAF(
        samples: mono,
        sampleRate: sampleRate,
        repetitions: 3,
        to: outputDirectory.appendingPathComponent("gong_end_triple.caf")
    )

    print(String(format: "Created gong_start.caf (one %.1f-second bell)", seconds))
    print(String(format: "Created gong_end_triple.caf (three consecutive bells, %.1f seconds)", seconds * 3))
} catch {
    fputs("error: \(error.localizedDescription)\n", stderr)
    exit(1)
}
