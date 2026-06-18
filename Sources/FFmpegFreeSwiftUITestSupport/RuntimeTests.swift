import Foundation
import FFmpegFreeSwiftUI

public struct TestMediaSet {
    var sourceMP4: URL
    var sourceMKV: URL
    var subtitleSRT: URL
    var subtitleASS: URL
}

public enum TestMediaFactory {
    public static func make(context: TestContext) throws -> TestMediaSet {
        guard let ffmpegPath = context.ffmpegPath else {
            throw TestSkip("ffmpeg not found")
        }

        let mediaDir = context.tempRoot.appendingPathComponent("media", isDirectory: true)
        try FileManager.default.createDirectory(at: mediaDir, withIntermediateDirectories: true)

        let sourceMP4 = mediaDir.appendingPathComponent("source.mp4")
        let sourceMKV = mediaDir.appendingPathComponent("source.mkv")
        let subtitleSRT = mediaDir.appendingPathComponent("source.srt")
        let subtitleASS = mediaDir.appendingPathComponent("source.ass")

        try writeSubtitleFiles(srt: subtitleSRT, ass: subtitleASS)

        if !FileManager.default.fileExists(atPath: sourceMP4.path) {
            try runFFmpeg(
                ffmpegPath: ffmpegPath,
                arguments: [
                    "-hide_banner", "-f", "lavfi", "-i", "testsrc2=size=128x72:rate=15:duration=1",
                    "-f", "lavfi", "-i", "sine=frequency=440:duration=1",
                    "-c:v", "mpeg4", "-q:v", "5", "-c:a", "aac", "-b:a", "64k",
                    "-pix_fmt", "yuv420p", "-shortest", sourceMP4.path, "-y"
                ],
                output: sourceMP4
            )
        }

        if !FileManager.default.fileExists(atPath: sourceMKV.path) {
            try runFFmpeg(
                ffmpegPath: ffmpegPath,
                arguments: [
                    "-hide_banner", "-i", sourceMP4.path,
                    "-i", subtitleSRT.path,
                    "-map", "0", "-map", "1",
                    "-c", "copy", "-c:s", "srt",
                    sourceMKV.path, "-y"
                ],
                output: sourceMKV
            )
        }

        return TestMediaSet(sourceMP4: sourceMP4, sourceMKV: sourceMKV, subtitleSRT: subtitleSRT, subtitleASS: subtitleASS)
    }

    private static func writeSubtitleFiles(srt: URL, ass: URL) throws {
        let srtText = """
        1
        00:00:00,000 --> 00:00:00,800
        FFmpegFreeSwiftUI test

        """
        try srtText.write(to: srt, atomically: true, encoding: .utf8)

        let assText = """
        [Script Info]
        ScriptType: v4.00+
        PlayResX: 128
        PlayResY: 72

        [V4+ Styles]
        Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
        Style: Default,Arial,12,&H00FFFFFF,&H000000FF,&H00000000,&H00000000,0,0,0,0,100,100,0,0,1,1,0,2,10,10,10,1

        [Events]
        Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
        Dialogue: 0,0:00:00.00,0:00:00.80,Default,,0,0,0,,FFmpegFreeSwiftUI test

        """
        try assText.write(to: ass, atomically: true, encoding: .utf8)
    }
}

public func makeRuntimeTests() -> [TestCase] {
    [
        TestCase("Runtime media", "Generates tiny source media", requiresFFmpeg: true) { context in
            let media = try TestMediaFactory.make(context: context)
            try expect(FileManager.default.fileExists(atPath: media.sourceMP4.path), "source mp4 should exist")
            try expect(FileManager.default.fileExists(atPath: media.sourceMKV.path), "source mkv should exist")
            try expect(FileManager.default.fileExists(atPath: media.subtitleSRT.path), "source srt should exist")
            try expect(FileManager.default.fileExists(atPath: media.subtitleASS.path), "source ass should exist")
        },
        TestCase("Runtime command", "Basic transcode", requiresFFmpeg: true) { context in
            let media = try TestMediaFactory.make(context: context)
            var preset = PresetData()
            preset.videoEncoder = "mpeg4"
            preset.imageQuality = ""
            preset.audioEncoder = "aac"
            preset.audioBitrate = "64k"
            preset.videoResolution = "96x54"
            preset.videoFrameRate = "12"
            let output = context.tempRoot.appendingPathComponent("basic.mp4")
            try runGeneratedCommand(context: context, preset: preset, input: media.sourceMP4.path, output: output.path)
        },
        TestCase("Runtime command", "Clip and filters", requiresFFmpeg: true) { context in
            let media = try TestMediaFactory.make(context: context)
            var preset = PresetData()
            preset.videoEncoder = "mpeg4"
            preset.audioEncoder = "aac"
            preset.clipMethod = .rough
            preset.clipInPoint = "00:00:00.10"
            preset.clipOutPoint = "00:00:00.80"
            preset.videoCrop = "96:54:0:0"
            preset.brightness = "0.02"
            preset.contrast = "1.0"
            preset.customAudioFilter = "volume=0.8"
            let output = context.tempRoot.appendingPathComponent("clip-filter.mp4")
            try runGeneratedCommand(context: context, preset: preset, input: media.sourceMP4.path, output: output.path)
        },
        TestCase("Runtime command", "Subtitle burn", requiresFFmpeg: true) { context in
            let media = try TestMediaFactory.make(context: context)
            guard try ffmpegFilterExists(context: context, filter: "subtitles") else {
                throw TestSkip("ffmpeg subtitles filter not available")
            }
            var preset = PresetData()
            preset.videoEncoder = "mpeg4"
            preset.audioEncoder = "aac"
            preset.subtitleExternalSource = true
            preset.subtitleBurnFilter = "subtitles"
            preset.externalSubtitleDirectory = media.subtitleASS.deletingLastPathComponent().path
            preset.externalSubtitleFileName = media.subtitleASS.lastPathComponent
            let output = context.tempRoot.appendingPathComponent("subtitle-burn.mp4")
            try runGeneratedCommand(context: context, preset: preset, input: media.sourceMP4.path, output: output.path)
        },
        TestCase("Runtime command", "Stream control and mov_text subtitles", requiresFFmpeg: true) { context in
            let media = try TestMediaFactory.make(context: context)
            var preset = PresetData()
            preset.videoEncoder = "copy"
            preset.audioEncoder = "copy"
            preset.subtitleStreamTargets = ["0:s:0"]
            preset.subtitleOperation = 2
            preset.metadataOption = 1
            preset.chapterOption = 2
            let output = context.tempRoot.appendingPathComponent("stream-control.mp4")
            try runGeneratedCommand(context: context, preset: preset, input: media.sourceMKV.path, output: output.path)
        },
        TestCase("Runtime command", "Auto mux sidecar subtitles", requiresFFmpeg: true) { context in
            let media = try TestMediaFactory.make(context: context)
            var preset = PresetData()
            preset.videoEncoder = "copy"
            preset.audioEncoder = "copy"
            preset.autoMuxSRT = true
            preset.autoMuxSubtitleToMovText = true
            let output = context.tempRoot.appendingPathComponent("auto-mux.mp4")
            try runGeneratedCommand(context: context, preset: preset, input: media.sourceMP4.path, output: output.path)
        },
        TestCase("Runtime command", "Image output", requiresFFmpeg: true) { context in
            let media = try TestMediaFactory.make(context: context)
            var preset = PresetData()
            preset.imageEncoder = "png"
            preset.videoFrameRate = "1"
            preset.audioEncoder = "禁用"
            preset.customAfterOutputArguments = "-frames:v 1"
            let output = context.tempRoot.appendingPathComponent("frame.png")
            try runGeneratedCommand(context: context, preset: preset, input: media.sourceMP4.path, output: output.path)
        },
        TestCase("Runtime command", "h264 VideoToolbox smoke", requiresFFmpeg: true) { context in
            let media = try TestMediaFactory.make(context: context)
            guard try ffmpegEncoderExists(context: context, encoder: "h264_videotoolbox") else {
                throw TestSkip("h264_videotoolbox encoder not available")
            }
            var preset = PresetData()
            preset.videoEncoder = "h264_videotoolbox"
            preset.pixelFormat = "nv12"
            preset.qualityArgumentName = "-q:v"
            preset.qualityValue = "60"
            preset.audioEncoder = "aac"
            preset.audioBitrate = "64k"
            let output = context.tempRoot.appendingPathComponent("h264-vt.mp4")
            try runGeneratedCommand(context: context, preset: preset, input: media.sourceMP4.path, output: output.path)
        },
        TestCase("Runtime command", "hevc VideoToolbox smoke", requiresFFmpeg: true) { context in
            let media = try TestMediaFactory.make(context: context)
            guard try ffmpegEncoderExists(context: context, encoder: "hevc_videotoolbox") else {
                throw TestSkip("hevc_videotoolbox encoder not available")
            }
            var preset = PresetData()
            preset.videoEncoder = "hevc_videotoolbox"
            preset.pixelFormat = "nv12"
            preset.qualityArgumentName = "-q:v"
            preset.qualityValue = "60"
            preset.audioEncoder = "aac"
            preset.audioBitrate = "64k"
            preset.advancedQualityArguments = ["-tag:v", "hvc1"]
            let output = context.tempRoot.appendingPathComponent("hevc-vt.mp4")
            try runGeneratedCommand(context: context, preset: preset, input: media.sourceMP4.path, output: output.path)
        },
        TestCase("Runtime command", "prores VideoToolbox smoke", requiresFFmpeg: true) { context in
            let media = try TestMediaFactory.make(context: context)
            guard try ffmpegEncoderExists(context: context, encoder: "prores_videotoolbox") else {
                throw TestSkip("prores_videotoolbox encoder not available")
            }
            var preset = PresetData()
            preset.videoEncoder = "prores_videotoolbox"
            preset.videoProfile = "proxy"
            preset.audioEncoder = "禁用"
            let output = context.tempRoot.appendingPathComponent("prores-vt.mov")
            try runGeneratedCommand(context: context, preset: preset, input: media.sourceMP4.path, output: output.path)
        },
        TestCase("Runtime quality", "PSNR and SSIM smoke", requiresFFmpeg: true) { context in
            let media = try TestMediaFactory.make(context: context)
            guard let ffmpegPath = context.ffmpegPath else { throw TestSkip("ffmpeg not found") }
            let distorted = context.tempRoot.appendingPathComponent("quality-distorted.mp4")
            try runFFmpeg(
                ffmpegPath: ffmpegPath,
                arguments: [
                    "-hide_banner", "-i", media.sourceMP4.path,
                    "-vf", "scale=128:72,format=yuv420p",
                    "-c:v", "mpeg4", "-q:v", "20", "-an",
                    distorted.path, "-y"
                ],
                output: distorted
            )
            for metric in [QualityMetric.psnr, .ssim] {
                guard try ffmpegFilterExists(context: context, filter: metric.filterName) else {
                    throw TestSkip("\(metric.filterName) filter not available")
                }
                let command = QualityAssessmentRunner.command(
                    metric: metric,
                    referenceFile: media.sourceMP4.path,
                    distortedFile: distorted.path,
                    configuration: QualityAssessmentConfiguration(duration: "0.5"),
                    logDirectory: context.tempRoot
                )
                let result = try runProcess(ffmpegPath, arguments: command.arguments, timeout: 30)
                guard result.status == 0 else {
                    throw TestFailure("quality ffmpeg failed: \(result.output)")
                }
                let parsed = QualityAssessmentRunner.parseResult(
                    metric: metric,
                    output: result.output,
                    logPath: command.logPath,
                    referenceFile: media.sourceMP4.path,
                    distortedFile: distorted.path,
                    elapsedSeconds: 1
                )
                try expect(parsed.score != "N/A", "\(metric.rawValue) should produce score")
            }
        },
        TestCase("Runtime quality", "Optional VMAF or XPSNR smoke", requiresFFmpeg: true) { context in
            let media = try TestMediaFactory.make(context: context)
            guard let ffmpegPath = context.ffmpegPath else { throw TestSkip("ffmpeg not found") }
            let availableMetrics = try [QualityMetric.vmaf, .xpsnr].filter { metric in
                try ffmpegFilterExists(context: context, filter: metric.filterName)
            }
            guard let metric = availableMetrics.first else {
                throw TestSkip("libvmaf and xpsnr filters not available")
            }
            let command = QualityAssessmentRunner.command(
                metric: metric,
                referenceFile: media.sourceMP4.path,
                distortedFile: media.sourceMP4.path,
                configuration: QualityAssessmentConfiguration(duration: "0.5"),
                logDirectory: context.tempRoot
            )
            let result = try runProcess(ffmpegPath, arguments: command.arguments, timeout: 40)
            guard result.status == 0 else {
                throw TestFailure("optional quality ffmpeg failed: \(result.output)")
            }
            let parsed = QualityAssessmentRunner.parseResult(
                metric: metric,
                output: result.output,
                logPath: command.logPath,
                referenceFile: media.sourceMP4.path,
                distortedFile: media.sourceMP4.path,
                elapsedSeconds: 1
            )
            try expect(parsed.score != "N/A", "\(metric.rawValue) should produce score")
        }
    ]
}

private func runGeneratedCommand(context: TestContext, preset: PresetData, input: String, output: String) throws {
    guard let ffmpegPath = context.ffmpegPath else {
        throw TestSkip("ffmpeg not found")
    }
    let built = FFmpegCommandBuilder().build(preset: preset, input: input, output: output)
    let arguments = splitCommandArguments(built, ffmpegPath: ffmpegPath)
    try runFFmpeg(ffmpegPath: ffmpegPath, arguments: arguments, output: URL(fileURLWithPath: output), command: built)
}

private func runFFmpeg(ffmpegPath: String, arguments: [String], output: URL, command: String? = nil) throws {
    let result = try runProcess(ffmpegPath, arguments: arguments, timeout: 30)
    guard result.status == 0 else {
        let rendered = command ?? "\(ffmpegPath) \(arguments.joined(separator: " "))"
        throw TestFailure("ffmpeg failed with status \(result.status)\nCommand: \(rendered)\nOutput:\n\(result.output)")
    }
    try expect(FileManager.default.fileExists(atPath: output.path), "runtime output should exist: \(output.path)")
    let attributes = try FileManager.default.attributesOfItem(atPath: output.path)
    let size = attributes[.size] as? NSNumber
    try expect((size?.intValue ?? 0) > 0, "runtime output should not be empty: \(output.path)")
}

private func ffmpegEncoderExists(context: TestContext, encoder: String) throws -> Bool {
    guard let ffmpegPath = context.ffmpegPath else { return false }
    let result = try runProcess(ffmpegPath, arguments: ["-hide_banner", "-h", "encoder=\(encoder)"], timeout: 10)
    return result.status == 0 && result.output.contains("Encoder \(encoder)")
}

private func ffmpegFilterExists(context: TestContext, filter: String) throws -> Bool {
    guard let ffmpegPath = context.ffmpegPath else { return false }
    let result = try runProcess(ffmpegPath, arguments: ["-hide_banner", "-filters"], timeout: 10)
    guard result.status == 0 else { return false }
    return result.output.split(whereSeparator: \.isNewline).contains { line in
        let parts = line.split(separator: " ").map(String.init)
        return parts.contains(filter)
    }
}
