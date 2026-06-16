import Foundation
import FFmpegFreeSwiftUI

private struct TestFailure: Error, CustomStringConvertible {
    let description: String
}

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw TestFailure(description: message)
    }
}

private func expectEqual<T: Equatable>(_ lhs: T, _ rhs: T, _ message: String) throws {
    if lhs != rhs {
        throw TestFailure(description: "\(message): \(lhs) != \(rhs)")
    }
}

private func testDecodesPartialChineseKeyPresetWithDefaults() throws {
    let json = """
    {
      "输出容器": "mkv",
      "视频参数_编码器_具体编码": "libx265",
      "视频参数_质量控制_参数名": "-crf",
      "视频参数_质量控制_值": "25"
    }
    """
    let preset = try JSONDecoder().decode(PresetData.self, from: Data(json.utf8))
    try expectEqual(preset.outputContainer, "mkv", "output container")
    try expectEqual(preset.videoEncoder, "libx265", "video encoder")
    try expectEqual(preset.qualityValue, "25", "quality")
    try expectEqual(preset.audioEncoder, "", "default audio")
}

private func testRoundTripsChineseKeys() throws {
    var preset = PresetData()
    preset.outputContainer = "mov"
    preset.videoEncoder = "hevc_videotoolbox"
    let data = try PresetIOService.encoder.encode(preset)
    let text = String(data: data, encoding: .utf8) ?? ""
    try expect(text.contains("输出容器"), "encoded JSON should contain Chinese output key")
    try expect(text.contains("视频参数_编码器_具体编码"), "encoded JSON should contain Chinese encoder key")
    let decoded = try PresetIOService.decoder.decode(PresetData.self, from: data)
    try expectEqual(decoded.outputContainer, "mov", "roundtrip output")
    try expectEqual(decoded.videoEncoder, "hevc_videotoolbox", "roundtrip encoder")
}

private func testAppSettingsDecodesWithoutNewPresetAutoLoadFields() throws {
    let json = """
    {
      "fontName": "System",
      "language": "zh",
      "maxConcurrentTasks": 2,
      "remotePort": "10591",
      "lastPreset": {
        "输出容器": "mp4"
      }
    }
    """
    let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))
    try expectEqual(settings.maxConcurrentTasks, 2, "settings existing field")
    try expectEqual(settings.presetAutoLoadMode, 0, "preset auto load default")
    try expectEqual(settings.presetAutoLoadPath, "", "preset auto load path default")
    try expectEqual(settings.lastPreset.outputContainer, "mp4", "settings last preset")
}

private func testBuildsBasicVideoAudioCommand() throws {
    var preset = PresetData()
    preset.outputContainer = "mp4"
    preset.videoEncoder = "libx264"
    preset.videoPreset = "slow"
    preset.qualityArgumentName = "-crf"
    preset.qualityValue = "22"
    preset.audioEncoder = "aac"
    preset.audioBitrate = "192k"
    let command = FFmpegCommandBuilder().build(preset: preset, input: "/tmp/input file.mkv", output: "/tmp/output.mp4")
    try expect(command.contains("-hide_banner -nostdin"), "basic command banner")
    try expect(command.contains("-i \"/tmp/input file.mkv\""), "quoted input")
    try expect(command.contains("-c:v libx264"), "video encoder")
    try expect(command.contains("-preset slow"), "preset")
    try expect(command.contains("-crf 22"), "quality")
    try expect(command.contains("-c:a aac"), "audio encoder")
    try expect(command.contains("-b:a 192k"), "audio bitrate")
}

private func testNormalizesQualityArgumentWithoutDash() throws {
    var preset = PresetData()
    preset.videoEncoder = "libx265"
    preset.qualityArgumentName = "cq"
    preset.qualityValue = "28"
    preset.audioQualityArgumentName = "q:a"
    preset.audioQualityValue = "4"
    let command = FFmpegCommandBuilder().build(preset: preset, input: "/tmp/in.mov", output: "/tmp/out.mp4")
    try expect(command.contains("-cq 28"), "video quality argument should be normalized")
    try expect(command.contains("-q:a 4"), "audio quality argument should be normalized")
    try expect(!command.contains(" cq "), "bare cq should not appear as an output-like argument")
}

private func testVideoToolboxCapabilityDefaults() throws {
    let h264 = try requireCapability("h264_videotoolbox")
    let hevc = try requireCapability("hevc_videotoolbox")
    let prores = try requireCapability("prores_videotoolbox")

    try expect(h264.pixelFormats.contains("nv12"), "h264 videotoolbox should include nv12")
    try expect(h264.pixelFormats.contains("yuv420p"), "h264 videotoolbox should include yuv420p")
    try expect(!h264.pixelFormats.contains("p010le"), "h264 videotoolbox should not suggest p010le")
    try expect(hevc.profiles.contains("main10"), "hevc videotoolbox should include main10")
    try expect(hevc.pixelFormats.contains("p010le"), "hevc videotoolbox should include p010le")
    try expect(hevc.pixelFormats.contains("p210le"), "hevc videotoolbox should include p210le")
    try expect(prores.profiles.contains("hq"), "prores videotoolbox should include hq")
    try expect(prores.profiles.contains("xq"), "prores videotoolbox should include xq")
}

private func testVideoToolboxCommandSkipsGenericEncoderOptions() throws {
    var preset = PresetData()
    preset.videoEncoder = "h264_videotoolbox"
    preset.videoPreset = "slow"
    preset.videoTune = "film"
    preset.videoGPU = "0"
    preset.videoThreads = "8"
    preset.videoProfile = "high"
    preset.pixelFormat = "nv12"
    preset.qualityArgumentName = "-q:v"
    preset.qualityValue = "60"
    preset.advancedQualityArguments = ["-realtime", "1"]

    let command = FFmpegCommandBuilder().build(preset: preset, input: "/tmp/in.mov", output: "/tmp/out.mp4")
    try expect(command.contains("-c:v h264_videotoolbox"), "videotoolbox encoder")
    try expect(command.contains("-profile:v high"), "videotoolbox profile")
    try expect(command.contains("-pix_fmt nv12"), "videotoolbox pix fmt")
    try expect(command.contains("-q:v 60"), "videotoolbox q:v")
    try expect(command.contains("-realtime 1"), "videotoolbox advanced args")
    try expect(!command.contains("-preset slow"), "videotoolbox should skip preset")
    try expect(!command.contains("-tune film"), "videotoolbox should skip tune")
    try expect(!command.contains("-gpu 0"), "videotoolbox should skip gpu")
    try expect(!command.contains("-threads:v 8"), "videotoolbox should skip video threads")
}

private func testVideoToolboxNotApplicableSelectionClearsGenericOptions() throws {
    var preset = PresetData()
    preset.videoEncoder = "hevc_videotoolbox"
    preset.videoPreset = ""
    preset.videoTune = ""
    preset.videoGPU = ""
    preset.videoThreads = ""
    let command = FFmpegCommandBuilder().build(preset: preset, input: "/tmp/in.mov", output: "/tmp/out.mp4")
    try expect(!command.contains("不适用 VideoToolbox"), "placeholder text should never enter command")
    try expect(!command.contains("-preset"), "empty videotoolbox preset should not emit")
    try expect(!command.contains("-tune"), "empty videotoolbox tune should not emit")
    try expect(!command.contains("-gpu"), "empty videotoolbox gpu should not emit")
    try expect(!command.contains("-threads:v"), "empty videotoolbox threads should not emit")
}

private func testVideoToolboxProbeParser() throws {
    let output = """
    Encoder hevc_videotoolbox [VideoToolbox H.265 Encoder]:
        Threading capabilities: none
        Supported pixel formats: videotoolbox_vld nv12 yuv420p bgra ayuv p010le p210le
    hevc_videotoolbox AVOptions:
      -profile           <int>        E..V....... Profile (from -99 to INT_MAX) (default -99)
         main            1            E..V....... Main Profile
         main10          2            E..V....... Main10 Profile
         rext            4            E..V....... Main 4:2:2 10 Profile
      -allow_sw          <boolean>    E..V....... Allow software encoding (default false)
      -realtime          <boolean>    E..V....... Hint that encoding should happen in real-time.
    """
    let capability = VideoEncoderCapabilityCatalog.parseProbeOutput(encoder: "hevc_videotoolbox", output: output)
    try expectEqual(capability.pixelFormats, ["nv12", "yuv420p", "bgra", "ayuv", "p010le", "p210le"], "probe pixel formats")
    try expectEqual(capability.profiles, ["main", "main10", "rext"], "probe profiles")
    try expect(capability.advancedQualityArguments.contains("-allow_sw 1"), "probe keeps available option")
    try expect(capability.advancedQualityArguments.contains("-realtime 1"), "probe keeps realtime option")
    try expect(capability.advancedQualityArguments.contains("-tag:v hvc1"), "probe keeps hvc1 compatibility tag")
}

private func testFullCustomArgumentsReplacePlaceholders() throws {
    var preset = PresetData()
    preset.customFullArguments = "-i <InputFile> -map 0 <OutputFile>"
    let command = FFmpegCommandBuilder().build(preset: preset, input: "/tmp/a.mov", output: "/tmp/b.mp4")
    try expectEqual(command, "-i /tmp/a.mov -map 0 /tmp/b.mp4", "full custom placeholders")
}

private func testStreamControlIndexesVideoAndAudioParameters() throws {
    var preset = PresetData()
    preset.keepOtherVideoStreams = true
    preset.videoStreamTargets = ["0:v:1"]
    preset.keepOtherAudioStreams = true
    preset.audioStreamTargets = ["0:a:0"]
    preset.videoEncoder = "libx265"
    preset.audioEncoder = "libopus"
    let command = FFmpegCommandBuilder().build(preset: preset, input: "/tmp/in.mkv", output: "/tmp/out.mkv")
    try expect(command.contains("-map 0:v? -c:v copy"), "video stream copy")
    try expect(command.contains("-c:v:1 libx265"), "indexed video encoder")
    try expect(command.contains("-map 0:a? -c:a copy"), "audio stream copy")
    try expect(command.contains("-c:a:0 libopus"), "indexed audio encoder")
}

private func testSubtitleBurnAddsFilter() throws {
    var preset = PresetData()
    preset.subtitleExternalSource = true
    preset.externalSubtitleDirectory = "/tmp"
    preset.externalSubtitleFileName = "sub.ass"
    let command = FFmpegCommandBuilder().build(preset: preset, input: "/tmp/in.mkv", output: "/tmp/out.mp4")
    try expect(command.contains("-vf"), "subtitle vf")
    try expect(command.contains("subtitles="), "subtitle filter")
    try expect(command.contains("sub.ass"), "subtitle file")
}

private func testParsesDurationAndProgressLine() throws {
    var progress = EncodingProgress()
    let parser = FFmpegProgressParser()
    try expect(parser.parse(line: "  Duration: 00:02:00.00, start: 0.000000, bitrate: 1000 kb/s", into: &progress, startedAt: Date()), "duration parse")
    try expectEqual(progress.totalTime, 120, "duration")
    try expect(parser.parse(line: "frame=  100 fps=25 q=23.0 size=    2048KiB time=00:01:00.00 bitrate=1200.0kbits/s speed=2.0x", into: &progress, startedAt: Date()), "progress parse")
    try expectEqual(progress.frame, "100", "frame")
    try expectEqual(progress.outputSizeKB, 2048, "size")
    try expectEqual(progress.currentTime, 60, "time")
    try expectEqual(progress.bitrate, "1200.0 kbps", "bitrate")
    try expectEqual(progress.speed, "2.0x", "speed")
    try expect(abs(progress.percent - 0.5) < 0.001, "percent")
}

private func testProgressParserIgnoresPlaceholderQuality() throws {
    var progress = EncodingProgress()
    progress.quality = "N/A"
    let parser = FFmpegProgressParser()
    try expect(parser.parse(line: "frame=   30 fps=0.0 q=-0.0 Lsize=N/A time=00:00:00.96 bitrate=N/A speed=9.34x", into: &progress, startedAt: Date()), "placeholder quality line should parse")
    try expectEqual(progress.quality, "N/A", "placeholder q should not replace quality")
    try expect(parser.parse(line: "frame=  100 fps=25 q=23.0 size=    2048KiB time=00:01:00.00 bitrate=1200.0kbits/s speed=2.0x", into: &progress, startedAt: Date()), "real quality line should parse")
    try expectEqual(progress.quality, "23.0", "real q should replace quality")
}

private func testOutputPathAndShellSplit() throws {
    var preset = PresetData()
    preset.outputContainer = "mkv"
    preset.useAutoNaming = true
    preset.autoNamingOption = .append3FUI
    try expectEqual(OutputPathBuilder.build(inputFile: "/tmp/input.mp4", preset: preset), "/tmp/input_3fui.mkv", "output path")
    try expectEqual(ShellQuoting.splitArguments("-i \"/tmp/a b.mov\" -c:v libx264"), ["-i", "/tmp/a b.mov", "-c:v", "libx264"], "shell split")
}

private func requireCapability(_ encoder: String) throws -> VideoEncoderCapability {
    guard let capability = VideoEncoderCapabilityCatalog.defaultCapability(for: encoder) else {
        throw TestFailure(description: "missing capability for \(encoder)")
    }
    return capability
}

let tests: [(String, () throws -> Void)] = [
    ("Preset partial decode", testDecodesPartialChineseKeyPresetWithDefaults),
    ("Preset roundtrip", testRoundTripsChineseKeys),
    ("Settings decode defaults", testAppSettingsDecodesWithoutNewPresetAutoLoadFields),
    ("Basic command", testBuildsBasicVideoAudioCommand),
    ("Quality argument normalization", testNormalizesQualityArgumentWithoutDash),
    ("VideoToolbox capability defaults", testVideoToolboxCapabilityDefaults),
    ("VideoToolbox command skips generic options", testVideoToolboxCommandSkipsGenericEncoderOptions),
    ("VideoToolbox not applicable clears generic options", testVideoToolboxNotApplicableSelectionClearsGenericOptions),
    ("VideoToolbox probe parser", testVideoToolboxProbeParser),
    ("Full custom placeholders", testFullCustomArgumentsReplacePlaceholders),
    ("Stream control", testStreamControlIndexesVideoAndAudioParameters),
    ("Subtitle burn", testSubtitleBurnAddsFilter),
    ("Progress parser", testParsesDurationAndProgressLine),
    ("Progress parser ignores placeholder quality", testProgressParserIgnoresPlaceholderQuality),
    ("Output path and shell split", testOutputPathAndShellSplit)
]

var failures: [String] = []
for (name, test) in tests {
    do {
        try test()
        print("PASS \(name)")
    } catch {
        failures.append("FAIL \(name): \(error)")
    }
}

if failures.isEmpty {
    print("All \(tests.count) tests passed")
} else {
    print(failures.joined(separator: "\n"))
    exit(1)
}
