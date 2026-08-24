#!/usr/bin/env swift

import AVFoundation
import Foundation

private struct Manifest: Decodable {
    struct Program: Decodable {
        struct GongPlacement: Decodable {
            let gong: String
            let offsetSeconds: Double
        }

        struct VoicePlacement: Decodable {
            let segment: String
            let offsetSeconds: Double
        }

        let mode: String
        let durationMinutes: Int
        let file: String
        let leadInSilenceSeconds: Double
        let gongLayout: [GongPlacement]
        let lengthSeconds: Double
        let layout: [VoicePlacement]
    }

    struct Gong: Decodable {
        let master: String
    }

    struct Gongs: Decodable {
        let start: Gong
        let warning: Gong
        let completion: Gong

        subscript(id: String) -> Gong? {
            switch id {
            case "start": start
            case "warning": warning
            case "completion": completion
            default: nil
            }
        }
    }

    let programs: [Program]
    let gongs: Gongs
}

private struct Clip {
    let label: String
    let url: URL
    let startSeconds: Double
}

private enum AssemblyError: LocalizedError {
    case missingAudioTrack(URL)
    case invalidTimeline(String)
    case cannotCreateTrack(String)
    case readerDidNotStart(String)
    case writerDidNotStart(String)
    case appendFailed(String)
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case let .missingAudioTrack(url):
            "No audio track found in \(url.path)."
        case let .invalidTimeline(message),
             let .cannotCreateTrack(message),
             let .readerDidNotStart(message),
             let .writerDidNotStart(message),
             let .appendFailed(message),
             let .exportFailed(message):
            message
        }
    }
}

private enum GuidedProgramAssembler {
    private static let voiceSources = [
        "settle": "audio/v2/recordings/guided-settle.mp3",
        "breath": "audio/v2/recordings/guided-breath.mp3",
        "sensations": "audio/v2/recordings/guided-sensations.mp3",
        "equanimity": "audio/v2/recordings/guided-equanimity.mp3",
        "metta": "audio/v2/recordings/shared-metta.mp3"
    ]

    static func run() async throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        let manifestURL = root.appendingPathComponent("audio/v2/cues.json")
        let manifest = try JSONDecoder().decode(
            Manifest.self,
            from: Data(contentsOf: manifestURL)
        )
        let outputDirectory = root.appendingPathComponent(
            "VipassanaTimer/Resources/GuidedPrograms",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )
        let silentTailURL = outputDirectory.appendingPathComponent(".assembly-tail-silence.caf")
        try makeSilentTail(at: silentTailURL)
        defer { try? FileManager.default.removeItem(at: silentTailURL) }

        for program in manifest.programs where program.mode == "guided" {
            let outputURL = outputDirectory.appendingPathComponent(program.file)
            var clips = try makeClips(
                for: program,
                manifest: manifest,
                root: root
            )
            clips.append(
                Clip(
                    label: "trailing silence",
                    url: silentTailURL,
                    startSeconds: program.lengthSeconds - 1
                )
            )
            clips.sort { $0.startSeconds < $1.startSeconds }
            try await assemble(clips: clips, program: program, outputURL: outputURL)
            print("Assembled \(program.file)")
        }
    }

    private static func makeSilentTail(at url: URL) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 48_000,
            channels: 1,
            interleaved: false
        ), let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 48_000) else {
            throw AssemblyError.invalidTimeline("Could not create the trailing-silence buffer.")
        }
        buffer.frameLength = 48_000
        if let samples = buffer.int16ChannelData?[0] {
            samples.initialize(repeating: 0, count: Int(buffer.frameLength))
        }
        let file = try AVAudioFile(
            forWriting: url,
            settings: format.settings,
            commonFormat: .pcmFormatInt16,
            interleaved: false
        )
        try file.write(from: buffer)
    }

    private static func makeClips(
        for program: Manifest.Program,
        manifest: Manifest,
        root: URL
    ) throws -> [Clip] {
        let voiceClips = try program.layout.map { placement in
            guard let source = voiceSources[placement.segment] else {
                throw AssemblyError.invalidTimeline(
                    "No provisional master is mapped for segment \(placement.segment)."
                )
            }
            return Clip(
                label: placement.segment,
                url: root.appendingPathComponent(source),
                startSeconds: program.leadInSilenceSeconds + placement.offsetSeconds
            )
        }

        let gongClips = try program.gongLayout.map { placement in
            guard let gong = manifest.gongs[placement.gong] else {
                throw AssemblyError.invalidTimeline("Unknown gong \(placement.gong).")
            }
            let gongURL = root
                .appendingPathComponent("audio/v2", isDirectory: true)
                .appendingPathComponent(gong.master)
                .standardizedFileURL
            return Clip(
                label: "\(placement.gong) gong",
                url: gongURL,
                startSeconds: program.leadInSilenceSeconds + placement.offsetSeconds
            )
        }

        return (voiceClips + gongClips).sorted { $0.startSeconds < $1.startSeconds }
    }

    private static func assemble(
        clips: [Clip],
        program: Manifest.Program,
        outputURL: URL
    ) async throws {
        let composition = AVMutableComposition()
        let totalDuration = CMTime(
            seconds: program.lengthSeconds,
            preferredTimescale: 48_000
        )
        composition.insertEmptyTimeRange(CMTimeRange(start: .zero, duration: totalDuration))

        var previousEnd = CMTime.zero
        for clip in clips {
            let asset = AVURLAsset(url: clip.url)
            guard let sourceTrack = try await asset.loadTracks(withMediaType: .audio).first else {
                throw AssemblyError.missingAudioTrack(clip.url)
            }
            let duration = try await asset.load(.duration)
            let start = CMTime(seconds: clip.startSeconds, preferredTimescale: 48_000)
            let end = start + duration
            guard start >= previousEnd else {
                throw AssemblyError.invalidTimeline(
                    "\(clip.label) overlaps the previous clip in \(program.file)."
                )
            }
            guard end <= totalDuration else {
                throw AssemblyError.invalidTimeline(
                    "\(clip.label) extends past the end of \(program.file)."
                )
            }
            guard let destinationTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else {
                throw AssemblyError.cannotCreateTrack(
                    "Could not create the composition track for \(clip.label)."
                )
            }
            try destinationTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: duration),
                of: sourceTrack,
                at: start
            )
            previousEnd = end
        }

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        let reader = try AVAssetReader(asset: composition)
        let readerOutput = AVAssetReaderAudioMixOutput(
            audioTracks: composition.tracks(withMediaType: .audio),
            audioSettings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 48_000,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsNonInterleaved: false
            ]
        )
        readerOutput.alwaysCopiesSampleData = false
        reader.add(readerOutput)

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .m4a)
        let writerInput = AVAssetWriterInput(
            mediaType: .audio,
            outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 48_000,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 96_000
            ]
        )
        writerInput.expectsMediaDataInRealTime = false
        writer.add(writerInput)

        guard writer.startWriting() else {
            throw AssemblyError.writerDidNotStart(
                writer.error?.localizedDescription ?? "The audio writer did not start."
            )
        }
        writer.startSession(atSourceTime: .zero)
        guard reader.startReading() else {
            writer.cancelWriting()
            throw AssemblyError.readerDidNotStart(
                reader.error?.localizedDescription ?? "The audio reader did not start."
            )
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let queue = DispatchQueue(label: "org.stillbell.guided-program-assembly")
            writerInput.requestMediaDataWhenReady(on: queue) {
                while writerInput.isReadyForMoreMediaData {
                    guard let sampleBuffer = readerOutput.copyNextSampleBuffer() else {
                        writerInput.markAsFinished()
                        writer.finishWriting {
                            if writer.status == .completed {
                                continuation.resume()
                            } else {
                                continuation.resume(throwing: AssemblyError.exportFailed(
                                    writer.error?.localizedDescription ??
                                        "Export failed for \(program.file)."
                                ))
                            }
                        }
                        return
                    }

                    guard writerInput.append(sampleBuffer) else {
                        reader.cancelReading()
                        writerInput.markAsFinished()
                        writer.cancelWriting()
                        continuation.resume(throwing: AssemblyError.appendFailed(
                            writer.error?.localizedDescription ??
                                "Could not append audio for \(program.file)."
                        ))
                        return
                    }
                }
            }
        }
    }
}

try await GuidedProgramAssembler.run()
