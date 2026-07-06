import Foundation

public enum VideoToolboxEncoderKind: String, CaseIterable, Sendable {
    case h264 = "h264_videotoolbox"
    case hevc = "hevc_videotoolbox"
    case prores = "prores_videotoolbox"

    public init?(encoder: String) {
        self.init(rawValue: encoder.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
    }
}

public struct VideoEncoderCapability: Equatable, Sendable {
    public var encoder: String
    public var supportsPreset: Bool
    public var supportsTune: Bool
    public var supportsThreads: Bool
    public var supportsGPUSelection: Bool
    public var presets: [String]
    public var profiles: [String]
    public var tunes: [String]
    public var pixelFormats: [String]
    public var qualityArguments: [String]
    public var qualityValues: [String]
    public var bitrateControlModes: [String]
    public var advancedQualityArguments: [String]

    public init(
        encoder: String,
        supportsPreset: Bool = true,
        supportsTune: Bool = true,
        supportsThreads: Bool = true,
        supportsGPUSelection: Bool = true,
        presets: [String] = [],
        profiles: [String] = [],
        tunes: [String] = [],
        pixelFormats: [String] = [],
        qualityArguments: [String] = [],
        qualityValues: [String] = [],
        bitrateControlModes: [String] = [],
        advancedQualityArguments: [String] = []
    ) {
        self.encoder = encoder
        self.supportsPreset = supportsPreset
        self.supportsTune = supportsTune
        self.supportsThreads = supportsThreads
        self.supportsGPUSelection = supportsGPUSelection
        self.presets = presets
        self.profiles = profiles
        self.tunes = tunes
        self.pixelFormats = pixelFormats
        self.qualityArguments = qualityArguments
        self.qualityValues = qualityValues
        self.bitrateControlModes = bitrateControlModes
        self.advancedQualityArguments = advancedQualityArguments
    }
}

public enum VideoEncoderCapabilityCatalog {
    public static func isVideoToolboxEncoder(_ encoder: String) -> Bool {
        VideoToolboxEncoderKind(encoder: encoder) != nil
    }

    public static func capability(for encoder: String, probed: [String: VideoEncoderCapability] = [:]) -> VideoEncoderCapability? {
        let key = encoder.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return probed[key] ?? defaultCapability(for: key)
    }

    public static func defaultCapability(for encoder: String) -> VideoEncoderCapability? {
        guard let kind = VideoToolboxEncoderKind(encoder: encoder) else { return nil }
        return defaultCapability(for: kind)
    }

    public static func probeVideoToolboxEncoders(ffmpegPath: String) async -> [String: VideoEncoderCapability] {
        await withTaskGroup(of: (String, VideoEncoderCapability)?.self) { group in
            for kind in VideoToolboxEncoderKind.allCases {
                group.addTask {
                    guard let output = await helpOutput(ffmpegPath: ffmpegPath, encoder: kind.rawValue) else {
                        return nil
                    }
                    return (kind.rawValue, parseProbeOutput(encoder: kind.rawValue, output: output))
                }
            }

            var capabilities: [String: VideoEncoderCapability] = [:]
            for await result in group {
                if let result {
                    capabilities[result.0] = result.1
                }
            }
            return capabilities
        }
    }

    public static func parseProbeOutput(encoder: String, output: String) -> VideoEncoderCapability {
        var capability = defaultCapability(for: encoder) ?? VideoEncoderCapability(encoder: encoder)
        let lines = output.split(whereSeparator: \.isNewline).map(String.init)

        if let formatsLine = lines.first(where: { $0.contains("Supported pixel formats:") }),
           let formats = formatsLine.split(separator: ":", maxSplits: 1).last {
            let values = formats
                .split(separator: " ")
                .map(String.init)
                .filter { !$0.isEmpty && $0 != "videotoolbox_vld" }
            if !values.isEmpty {
                capability.pixelFormats = values
            }
        }

        let profiles = optionValues(named: "-profile", in: lines)
        if !profiles.isEmpty {
            capability.profiles = profiles
        }

        let availableOptions = Set(lines.compactMap { line -> String? in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("-") else { return nil }
            return trimmed.split(separator: " ").first.map(String.init)
        })

        let filteredAdvanced = capability.advancedQualityArguments.filter { argument in
            guard let option = argument.split(separator: " ").first.map(String.init) else { return false }
            return option == "-tag:v" || availableOptions.contains(option)
        }
        if !filteredAdvanced.isEmpty {
            capability.advancedQualityArguments = filteredAdvanced
        }

        return capability
    }

    private static func defaultCapability(for kind: VideoToolboxEncoderKind) -> VideoEncoderCapability {
        let commonAdvanced = [
            "-allow_sw 1",
            "-require_sw 1",
            "-realtime 1",
            "-frames_before 1",
            "-frames_after 1",
            "-prio_speed 1",
            "-power_efficient 1",
            "-spatial_aq 1",
            "-max_ref_frames 1"
        ]
        let qualityArguments = ["", "-q:v"]
        let qualityValues = ["", "50", "55", "65", "75", "80"]
        let bitrateModes = [
            "",
            "控大小：平均码率 -b:v",
            "省心画质：质量等级 -q:v 65",
            "限制峰值：-maxrate/-bufsize",
            "平台要求：恒定码率 -constant_bit_rate 1",
            "直播录屏：实时编码 -realtime 1"
        ]

        switch kind {
        case .h264:
            return VideoEncoderCapability(
                encoder: kind.rawValue,
                supportsPreset: false,
                supportsTune: false,
                supportsThreads: false,
                supportsGPUSelection: false,
                presets: [],
                profiles: ["baseline", "constrained_baseline", "main", "high", "constrained_high", "extended"],
                tunes: [],
                pixelFormats: ["nv12", "yuv420p"],
                qualityArguments: qualityArguments,
                qualityValues: qualityValues,
                bitrateControlModes: bitrateModes,
                advancedQualityArguments: commonAdvanced + [
                    "-level 4.1",
                    "-coder cabac",
                    "-coder cavlc",
                    "-a53cc 1",
                    "-constant_bit_rate 1",
                    "-max_slice_bytes 0"
                ]
            )
        case .hevc:
            return VideoEncoderCapability(
                encoder: kind.rawValue,
                supportsPreset: false,
                supportsTune: false,
                supportsThreads: false,
                supportsGPUSelection: false,
                presets: [],
                profiles: ["main", "main10", "main42210", "rext"],
                tunes: [],
                pixelFormats: ["nv12", "yuv420p", "bgra", "ayuv", "p010le", "p210le"],
                qualityArguments: qualityArguments,
                qualityValues: qualityValues,
                bitrateControlModes: bitrateModes,
                advancedQualityArguments: commonAdvanced + [
                    "-alpha_quality 1",
                    "-constant_bit_rate 1",
                    "-tag:v hvc1"
                ]
            )
        case .prores:
            return VideoEncoderCapability(
                encoder: kind.rawValue,
                supportsPreset: false,
                supportsTune: false,
                supportsThreads: false,
                supportsGPUSelection: false,
                presets: [],
                profiles: ["auto", "proxy", "lt", "standard", "hq", "4444", "xq"],
                tunes: [],
                pixelFormats: ["yuv420p", "nv12", "ayuv64le", "uyvy422", "p010le", "nv16", "p210le", "p216le", "nv24", "p410le", "p416le", "bgra"],
                qualityArguments: [""],
                qualityValues: [""],
                bitrateControlModes: ["", "ProRes profile 控制质量档位"],
                advancedQualityArguments: commonAdvanced
            )
        }
    }

    private static func optionValues(named optionName: String, in lines: [String]) -> [String] {
        guard let start = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix(optionName + " ") }) else {
            return []
        }

        var values: [String] = []
        for line in lines.dropFirst(start + 1) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("-") { break }
            guard let token = trimmed.split(separator: " ").first.map(String.init), !token.isEmpty else {
                continue
            }
            if token.first?.isLetter == true || token.first?.isNumber == true {
                values.append(token)
            }
        }
        return values
    }

    private static func helpOutput(ffmpegPath: String, encoder: String) async -> String? {
        await Task.detached(priority: .utility) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: ffmpegPath)
            process.arguments = ["-hide_banner", "-h", "encoder=\(encoder)"]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
                process.waitUntilExit()
                guard process.terminationStatus == 0 else { return nil }
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                return String(data: data, encoding: .utf8)
            } catch {
                return nil
            }
        }.value
    }
}

public struct FFmpegCommandBuilder: Sendable {
    public init() {}

    public func build(preset: PresetData, input: String, output: String) -> String {
        if !preset.customFullArguments.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return replacePlaceholders(preset.customFullArguments, input: input, output: output)
        }

        var args: [String] = ["-hide_banner", "-nostdin"]
        appendSplit(preset.customLeadingArguments, to: &args)
        appendDecoding(preset, to: &args)
        appendInputClip(preset, to: &args)
        appendInput(preset, input: input, to: &args)
        appendAutoMuxInputs(preset, input: input, to: &args)
        appendSplit(preset.customBeforeOutputArguments, to: &args)

        var videoFilters = buildVideoFilters(preset: preset, input: input)
        var audioFilters = buildAudioFilters(preset: preset)
        appendCustomFilters(preset: preset, videoFilters: &videoFilters, audioFilters: &audioFilters)

        let videoArguments = buildVideoArguments(preset: preset)
        let audioArguments = buildAudioArguments(preset: preset)
        appendStreamControl(
            preset: preset,
            videoArguments: videoArguments,
            videoFilters: videoFilters,
            audioArguments: audioArguments,
            audioFilters: audioFilters,
            to: &args
        )
        appendSubtitleControl(preset: preset, to: &args)
        appendGlobalOutputOptions(preset: preset, to: &args)
        appendSplit(preset.customAfterOutputArguments, to: &args)

        if !preset.omitOutputFileArgument, !output.isEmpty {
            args.append(ShellQuoting.quote(output))
        }

        appendSplit(preset.customTrailingArguments, to: &args)
        args.append("-y")
        return args.joined(separator: " ")
    }

    public func overview(preset: PresetData) -> String {
        var lines: [String] = []
        lines.append("输出容器: \(preset.outputContainer)")
        lines.append("视频编码器: \(preset.videoEncoder.isEmpty ? "默认" : preset.videoEncoder)")
        lines.append("音频编码器: \(preset.audioEncoder.isEmpty ? "默认" : preset.audioEncoder)")
        if VideoEncoderCapabilityCatalog.isVideoToolboxEncoder(preset.videoEncoder) {
            appendVideoToolboxQualityOverview(preset: preset, to: &lines)
        } else if let qualityArgument = normalizedOptionName(preset.qualityArgumentName), !preset.qualityValue.isEmpty {
            lines.append("质量: \(qualityArgument) \(preset.qualityValue)")
        }
        if !preset.videoResolution.isEmpty { lines.append("分辨率: \(preset.videoResolution)") }
        if !preset.videoFrameRate.isEmpty { lines.append("帧率: \(preset.videoFrameRate)") }
        appendVideoToolboxWarnings(preset: preset, to: &lines)
        if !preset.customFullArguments.isEmpty { lines.append("完全自己写模式已启用") }
        return lines.joined(separator: "\n")
    }

    private func appendDecoding(_ preset: PresetData, to args: inout [String]) {
        if !preset.decoder.isEmpty {
            args += ["-hwaccel", preset.decoder]
        }
        if !preset.decoderCPUThreads.isEmpty {
            args += ["-threads", preset.decoderCPUThreads]
        }
        if !preset.decoderOutputFormat.isEmpty {
            args += ["-hwaccel_output_format", preset.decoderOutputFormat]
        }
        if !preset.decoderHardwareArgumentName.isEmpty, !preset.decoderHardwareArgument.isEmpty {
            args += [preset.decoderHardwareArgumentName, preset.decoderHardwareArgument]
        }
    }

    private func appendInputClip(_ preset: PresetData, to args: inout [String]) {
        switch preset.clipMethod {
        case .rough:
            if !preset.clipInPoint.isEmpty { args += ["-ss", preset.clipInPoint] }
            if !preset.clipOutPoint.isEmpty { args += ["-to", preset.clipOutPoint] }
        case .preciseWithPreseek:
            if !preset.clipPreDecodeSeconds.isEmpty,
               let inPoint = seconds(from: preset.clipInPoint),
               let predecode = seconds(from: preset.clipPreDecodeSeconds) {
                args += ["-ss", timeString(max(inPoint - predecode, 0))]
            }
        default:
            break
        }
    }

    private func appendInput(_ preset: PresetData, input: String, to args: inout [String]) {
        if preset.useAviSynth {
            let url = URL(fileURLWithPath: input)
            let path = url.deletingPathExtension().appendingPathExtension("avs").path
            args += ["-i", ShellQuoting.quote(path)]
        } else if preset.useVapourSynth {
            let url = URL(fileURLWithPath: input)
            let ext = URL(fileURLWithPath: preset.vapourSynthScript).pathExtension
            let path = url.deletingPathExtension().appendingPathExtension(ext.isEmpty ? "vpy" : ext).path
            args += ["-f", "vapoursynth", "-i", ShellQuoting.quote(path)]
        } else {
            args += ["-i", ShellQuoting.quote(input)]
        }
    }

    private func appendAutoMuxInputs(_ preset: PresetData, input: String, to args: inout [String]) {
        let url = URL(fileURLWithPath: input)
        let base = url.deletingPathExtension()
        let candidates: [(Bool, String)] = [
            (preset.autoMuxSRT, "srt"),
            (preset.autoMuxASS, "ass"),
            (preset.autoMuxSSA, "ssa")
        ]
        for (enabled, ext) in candidates where enabled {
            let path = base.appendingPathExtension(ext).path
            if FileManager.default.fileExists(atPath: path) {
                args += ["-i", ShellQuoting.quote(path)]
            }
        }
    }

    private func buildVideoArguments(preset: PresetData) -> [String] {
        var args: [String] = []
        let isVideoToolbox = VideoEncoderCapabilityCatalog.isVideoToolboxEncoder(preset.videoEncoder)
        if !preset.videoEncoder.isEmpty {
            args += ["-c:v", preset.videoEncoder]
        }
        if !isVideoToolbox, !preset.videoPreset.isEmpty {
            args += ["-preset", preset.videoPreset]
        }
        if !preset.videoProfile.isEmpty {
            args += ["-profile:v", preset.videoProfile]
        }
        if !isVideoToolbox, !preset.videoTune.isEmpty {
            args += ["-tune", preset.videoTune]
        }
        if !isVideoToolbox, !preset.videoGPU.isEmpty {
            args += ["-gpu", preset.videoGPU]
        }
        if !isVideoToolbox, !preset.videoThreads.isEmpty {
            args += ["-threads:v", preset.videoThreads]
        }
        if !preset.videoFrameRate.isEmpty {
            args += ["-r", preset.videoFrameRate]
        }
        if !preset.videoResolution.isEmpty {
            args += ["-s", preset.videoResolution]
        }
        if isVideoToolbox, !preset.pixelFormat.isEmpty {
            args += ["-pix_fmt", preset.pixelFormat]
        }
        if let qualityArgument = videoQualityArgument(preset: preset), !preset.qualityValue.isEmpty {
            args += [qualityArgument, preset.qualityValue]
        }
        if !preset.bitrateBase.isEmpty { args += ["-b:v", preset.bitrateBase] }
        if !preset.bitrateMin.isEmpty { args += ["-minrate", preset.bitrateMin] }
        if !preset.bitrateMax.isEmpty { args += ["-maxrate", preset.bitrateMax] }
        if !preset.bitrateBuffer.isEmpty { args += ["-bufsize", preset.bitrateBuffer] }
        appendPlain(preset.advancedQualityArguments, to: &args)
        appendSplit(preset.customVideoArguments, to: &args)
        if !preset.imageEncoder.isEmpty {
            args += ["-c:v", preset.imageEncoder]
            if !preset.imageQuality.isEmpty { args += ["-q:v", preset.imageQuality] }
        }
        return args
    }

    private func buildAudioArguments(preset: PresetData) -> [String] {
        var args: [String] = []
        if !preset.audioEncoder.isEmpty {
            switch preset.audioEncoder.lowercased() {
            case "禁用", "disable", "none", "an":
                args.append("-an")
            default:
                args += ["-c:a", preset.audioEncoder]
            }
        }
        if !preset.audioBitrate.isEmpty { args += ["-b:a", preset.audioBitrate] }
        if let audioQualityArgument = normalizedOptionName(preset.audioQualityArgumentName), !preset.audioQualityValue.isEmpty {
            args += [audioQualityArgument, preset.audioQualityValue]
        }
        if !preset.audioChannels.isEmpty { args += ["-ac", preset.audioChannels] }
        if !preset.audioSampleRate.isEmpty { args += ["-ar", preset.audioSampleRate] }
        appendSplit(preset.customAudioArguments, to: &args)
        return args
    }

    private func buildVideoFilters(preset: PresetData, input: String) -> [String] {
        var filters: [String] = []
        switch preset.deinterlaceMode {
        case 1: filters.append("yadif=0:-1:0")
        case 2: filters.append("yadif=0:0:0")
        case 3: filters.append("yadif=0:1:0")
        default: break
        }
        if !preset.videoCrop.isEmpty { filters.append("crop=\(preset.videoCrop)") }
        if !preset.decimateMaxChangeRatio.isEmpty {
            filters.append("mpdecimate=frac=\(preset.decimateMaxChangeRatio)")
        }
        if !preset.interpolateTargetFPS.isEmpty {
            var parts = ["fps=\(preset.interpolateTargetFPS)"]
            if !preset.interpolateMode.isEmpty { parts.append("mi_mode=\(preset.interpolateMode)") }
            if !preset.interpolateME.isEmpty { parts.append("me_mode=\(preset.interpolateME)") }
            if !preset.interpolateSearchAlgorithm.isEmpty { parts.append("me=\(preset.interpolateSearchAlgorithm)") }
            if !preset.interpolateMCMode.isEmpty { parts.append("mc_mode=\(preset.interpolateMCMode)") }
            if preset.interpolateVariableBlock { parts.append("vsbmc=1") }
            if !preset.interpolateBlockSize.isEmpty { parts.append("mb_size=\(preset.interpolateBlockSize)") }
            if !preset.interpolateSearchRange.isEmpty { parts.append("search_param=\(preset.interpolateSearchRange)") }
            if !preset.interpolateSceneChange.isEmpty { parts.append("scd_threshold=\(preset.interpolateSceneChange)") }
            filters.append("minterpolate=\(parts.joined(separator: ":"))")
        }
        if !preset.blendMode.isEmpty || !preset.blendRatio.isEmpty {
            var parts: [String] = []
            if !preset.blendMode.isEmpty { parts.append("all_mode=\(preset.blendMode)") }
            if !preset.blendRatio.isEmpty { parts.append("opacity=\(preset.blendRatio)") }
            filters.append("tblend=\(parts.joined(separator: ":"))")
        }
        if !preset.upscaleWidth.isEmpty || !preset.upscaleHeight.isEmpty || !preset.upscaleAlgorithm.isEmpty || !preset.downscaleAlgorithm.isEmpty || !preset.shaderList.isEmpty {
            var parts: [String] = []
            if !preset.upscaleWidth.isEmpty { parts.append("w=\(preset.upscaleWidth)") }
            if !preset.upscaleHeight.isEmpty { parts.append("h=\(preset.upscaleHeight)") }
            if !preset.upscaleAlgorithm.isEmpty { parts.append("upscaler=\(preset.upscaleAlgorithm)") }
            if !preset.downscaleAlgorithm.isEmpty { parts.append("downscaler=\(preset.downscaleAlgorithm)") }
            if !preset.antiRingingStrength.isEmpty { parts.append("antiringing=\(preset.antiRingingStrength)") }
            for shader in preset.shaderList where !shader.isEmpty {
                parts.append("custom_shader_path='\(ShellQuoting.ffmpegFilterPath(shader))'")
            }
            filters.append("libplacebo=\(parts.joined(separator: ":"))")
        }
        if !preset.pixelFormat.isEmpty, !VideoEncoderCapabilityCatalog.isVideoToolboxEncoder(preset.videoEncoder) {
            filters.append("format=\(preset.pixelFormat)")
        }
        if !preset.colorMatrix.isEmpty || !preset.colorPrimaries.isEmpty || !preset.colorTransfer.isEmpty || !preset.colorRange.isEmpty || !preset.tonemapAlgorithm.isEmpty {
            var parts: [String] = []
            if !preset.colorMatrix.isEmpty { parts.append("matrix=\(preset.colorMatrix)") }
            if !preset.colorPrimaries.isEmpty { parts.append("primaries=\(preset.colorPrimaries)") }
            if !preset.colorTransfer.isEmpty { parts.append("transfer=\(preset.colorTransfer)") }
            if !preset.colorRange.isEmpty { parts.append("range=\(preset.colorRange)") }
            if !preset.tonemapAlgorithm.isEmpty { parts.append("tonemap=\(preset.tonemapAlgorithm)") }
            filters.append((preset.colorFilter.isEmpty ? "zscale" : preset.colorFilter) + "=\(parts.joined(separator: ":"))")
        }
        var eq: [String] = []
        if !preset.brightness.isEmpty { eq.append("brightness=\(preset.brightness)") }
        if !preset.contrast.isEmpty { eq.append("contrast=\(preset.contrast)") }
        if !preset.saturation.isEmpty { eq.append("saturation=\(preset.saturation)") }
        if !preset.gamma.isEmpty { eq.append("gamma=\(preset.gamma)") }
        if !eq.isEmpty { filters.append("eq=\(eq.joined(separator: ":"))") }
        appendDenoiseAndSharpen(preset, to: &filters)
        appendFlipAndRotate(preset, to: &filters)
        appendSubtitleBurn(preset, input: input, to: &filters)
        return filters
    }

    private func buildAudioFilters(preset: PresetData) -> [String] {
        var filters: [String] = []
        if !preset.loudnormTarget.isEmpty || !preset.loudnormRange.isEmpty || !preset.loudnormPeak.isEmpty {
            var parts: [String] = []
            if !preset.loudnormTarget.isEmpty { parts.append("I=\(preset.loudnormTarget)") }
            if !preset.loudnormRange.isEmpty { parts.append("LRA=\(preset.loudnormRange)") }
            if !preset.loudnormPeak.isEmpty { parts.append("TP=\(preset.loudnormPeak)") }
            filters.append("loudnorm=\(parts.joined(separator: ":"))")
        }
        return filters
    }

    private func appendCustomFilters(preset: PresetData, videoFilters: inout [String], audioFilters: inout [String]) {
        if !preset.customVideoFilter.isEmpty {
            videoFilters.append(contentsOf: preset.customVideoFilter.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
        }
        if !preset.customAudioFilter.isEmpty {
            audioFilters.append(contentsOf: preset.customAudioFilter.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
        }
        if !preset.customFilterComplex.isEmpty {
            videoFilters.removeAll()
            audioFilters.removeAll()
        }
    }

    private func appendStreamControl(
        preset: PresetData,
        videoArguments: [String],
        videoFilters: [String],
        audioArguments: [String],
        audioFilters: [String],
        to args: inout [String]
    ) {
        let needsVideoMap = preset.keepOtherVideoStreams || !preset.videoStreamTargets.isEmpty
        if needsVideoMap {
            if preset.keepOtherVideoStreams {
                args += ["-map", "0:v?", "-c:v", "copy"]
                let targets = preset.videoStreamTargets.isEmpty ? ["0"] : preset.videoStreamTargets.map(extractStreamIndex)
                for target in targets {
                    appendIndexedVideo(videoArguments: videoArguments, filters: videoFilters, index: target, to: &args)
                }
            } else {
                for target in preset.videoStreamTargets { args += ["-map", "\(target)?"] }
                appendPlain(videoArguments, to: &args)
                if !videoFilters.isEmpty { args += ["-vf", ShellQuoting.quote(videoFilters.joined(separator: ","))] }
            }
        } else {
            appendPlain(videoArguments, to: &args)
            if !videoFilters.isEmpty { args += ["-vf", ShellQuoting.quote(videoFilters.joined(separator: ","))] }
        }

        let needsAudioMap = preset.keepOtherAudioStreams || !preset.audioStreamTargets.isEmpty
        if needsAudioMap {
            if preset.keepOtherAudioStreams {
                args += ["-map", "0:a?", "-c:a", "copy"]
                let targets = preset.audioStreamTargets.isEmpty ? ["0"] : preset.audioStreamTargets.map(extractStreamIndex)
                for target in targets {
                    appendIndexedAudio(audioArguments: audioArguments, filters: audioFilters, index: target, to: &args)
                }
            } else {
                for target in preset.audioStreamTargets { args += ["-map", "\(target)?"] }
                appendPlain(audioArguments, to: &args)
                if !audioFilters.isEmpty { args += ["-af", ShellQuoting.quote(audioFilters.joined(separator: ","))] }
            }
        } else {
        appendPlain(audioArguments, to: &args)
            if !audioFilters.isEmpty { args += ["-af", ShellQuoting.quote(audioFilters.joined(separator: ","))] }
        }
        if !preset.customFilterComplex.isEmpty {
            args += ["-filter_complex", ShellQuoting.quote(preset.customFilterComplex)]
        }
    }

    private func appendSubtitleControl(preset: PresetData, to args: inout [String]) {
        var codec = ""
        switch preset.subtitleOperation {
        case 1: codec = "copy"
        case 2: codec = "mov_text"
        case 3: codec = "srt"
        case 4: codec = "ass"
        case 5: codec = "ssa"
        default: break
        }

        if preset.keepOtherSubtitleStreams {
            args += ["-map", "0:s?", "-c:s", "copy"]
        }
        for target in preset.subtitleStreamTargets {
            args += ["-map", "\(target)?"]
        }
        if !codec.isEmpty {
            args += ["-c:s", codec]
        }
        if preset.autoMuxSubtitleToMovText {
            args += ["-c:s", "mov_text"]
        }
    }

    private func appendGlobalOutputOptions(preset: PresetData, to args: inout [String]) {
        switch preset.metadataOption {
        case 1: args += ["-map_metadata", "0"]
        case 2: args += ["-map_metadata", "-1"]
        default: break
        }
        switch preset.chapterOption {
        case 1: args += ["-map_chapters", "0"]
        case 2: args += ["-map_chapters", "-1"]
        default: break
        }
        switch preset.attachmentOption {
        case 1: args += ["-map", "0:t?"]
        case 2: args += ["-map", "-0:t?"]
        default: break
        }
        if preset.clipMethod == .preciseFromStart || preset.clipMethod == .trimFilter || preset.clipMethod == .trimHeadTail {
            if !preset.clipInPoint.isEmpty { args += ["-ss", preset.clipInPoint] }
            if !preset.clipOutPoint.isEmpty { args += ["-to", preset.clipOutPoint] }
        }
    }

    private func appendDenoiseAndSharpen(_ preset: PresetData, to filters: inout [String]) {
        switch preset.denoiseMode.lowercased() {
        case "hqdn3d":
            filters.append("hqdn3d=\([preset.denoiseParameter1, preset.denoiseParameter2, preset.denoiseParameter3, preset.denoiseParameter4].filter { !$0.isEmpty }.joined(separator: ":"))")
        case "nlmeans":
            filters.append("nlmeans=\([preset.denoiseParameter1, preset.denoiseParameter2, preset.denoiseParameter3, preset.denoiseParameter4].filter { !$0.isEmpty }.joined(separator: ":"))")
        case "atadenoise", "bm3d":
            filters.append(preset.denoiseMode + (preset.denoiseParameter1.isEmpty ? "" : "=\(preset.denoiseParameter1)"))
        default:
            break
        }
        if !preset.sharpenWidth.isEmpty || !preset.sharpenHeight.isEmpty || !preset.sharpenStrength.isEmpty {
            let width = preset.sharpenWidth.isEmpty ? "5" : preset.sharpenWidth
            let height = preset.sharpenHeight.isEmpty ? "5" : preset.sharpenHeight
            let strength = preset.sharpenStrength.isEmpty ? "1.0" : preset.sharpenStrength
            filters.append("unsharp=\(width):\(height):\(strength)")
        }
    }

    private func appendFlipAndRotate(_ preset: PresetData, to filters: inout [String]) {
        switch preset.rotateMode {
        case 1: filters.append("transpose=1")
        case 2: filters.append("transpose=2")
        case 3: filters.append("transpose=1,transpose=1")
        default: break
        }
        switch preset.mirrorMode {
        case 1: filters.append("hflip")
        case 2: filters.append("vflip")
        case 3: filters.append("hflip,vflip")
        default: break
        }
    }

    private func appendSubtitleBurn(_ preset: PresetData, input: String, to filters: inout [String]) {
        guard preset.subtitleExternalSource || preset.subtitleEmbeddedSource else { return }
        var source = ""
        if preset.subtitleExternalSource {
            if !preset.externalSubtitleFileName.isEmpty {
                let directory = preset.externalSubtitleDirectory.isEmpty ? URL(fileURLWithPath: input).deletingLastPathComponent().path : preset.externalSubtitleDirectory
                source = URL(fileURLWithPath: directory).appendingPathComponent(preset.externalSubtitleFileName).path
            }
        } else if preset.subtitleEmbeddedSource {
            source = input
        }
        guard !source.isEmpty else { return }
        let filterName = preset.subtitleBurnFilter.isEmpty ? "subtitles" : preset.subtitleBurnFilter
        var parts = ["filename='\(ShellQuoting.ffmpegFilterPath(source))'"]
        if preset.subtitleEmbeddedSource, !preset.embeddedSubtitleStream.isEmpty {
            parts.append("si=\(extractStreamIndex(preset.embeddedSubtitleStream))")
        }
        if !preset.subtitleFontsDirectory.isEmpty {
            parts.append("fontsdir='\(ShellQuoting.ffmpegFilterPath(preset.subtitleFontsDirectory))'")
        }
        let style = forceStyle(preset)
        if !style.isEmpty {
            parts.append("force_style='\(style)'")
        }
        if !preset.subtitleCustomFilterArguments.isEmpty {
            parts.append(preset.subtitleCustomFilterArguments)
        }
        filters.append("\(filterName)=\(parts.joined(separator: ":"))")
    }

    private func forceStyle(_ preset: PresetData) -> String {
        var style: [String] = []
        if !preset.subtitleStyleName.isEmpty { style.append("FontName=\(preset.subtitleStyleName)") }
        if preset.subtitleStyleSize > 0 { style.append("FontSize=\(trimFloat(preset.subtitleStyleSize))") }
        if preset.subtitleBold { style.append("Bold=1") }
        if preset.subtitleItalic { style.append("Italic=1") }
        if preset.subtitleUnderline { style.append("Underline=1") }
        if preset.subtitleStrikeout { style.append("StrikeOut=1") }
        if preset.subtitleBorderStyle > 0 { style.append("BorderStyle=\(preset.subtitleBorderStyle)") }
        if !preset.subtitleOutlineWidth.isEmpty { style.append("Outline=\(preset.subtitleOutlineWidth)") }
        if !preset.subtitleShadowDistance.isEmpty { style.append("Shadow=\(preset.subtitleShadowDistance)") }
        if !preset.subtitlePrimaryColor.isTransparent { style.append("PrimaryColour=\(assColor(preset.subtitlePrimaryColor, alpha: preset.subtitlePrimaryAlpha))") }
        if !preset.subtitleSecondaryColor.isTransparent { style.append("SecondaryColour=\(assColor(preset.subtitleSecondaryColor, alpha: preset.subtitleSecondaryAlpha))") }
        if !preset.subtitleOutlineColor.isTransparent { style.append("OutlineColour=\(assColor(preset.subtitleOutlineColor, alpha: preset.subtitleOutlineAlpha))") }
        if !preset.subtitleBackColor.isTransparent { style.append("BackColour=\(assColor(preset.subtitleBackColor, alpha: preset.subtitleBackAlpha))") }
        if preset.subtitleAlignment > 0 { style.append("Alignment=\(preset.subtitleAlignment)") }
        if !preset.subtitleMarginV.isEmpty { style.append("MarginV=\(preset.subtitleMarginV)") }
        if !preset.subtitleMarginL.isEmpty { style.append("MarginL=\(preset.subtitleMarginL)") }
        if !preset.subtitleMarginR.isEmpty { style.append("MarginR=\(preset.subtitleMarginR)") }
        if !preset.subtitleSpacing.isEmpty { style.append("Spacing=\(preset.subtitleSpacing)") }
        if !preset.subtitleLineSpacing.isEmpty { style.append("LineSpacing=\(preset.subtitleLineSpacing)") }
        if !preset.subtitleCustomStyle.isEmpty { style.append(preset.subtitleCustomStyle) }
        return style.joined(separator: ",")
    }

    private func appendIndexedVideo(videoArguments: [String], filters: [String], index: String, to args: inout [String]) {
        if !filters.isEmpty {
            args += ["-filter:v:\(index)", ShellQuoting.quote(filters.joined(separator: ","))]
        }
        var iterator = videoArguments.makeIterator()
        while let item = iterator.next() {
            if item == "-c:v", let value = iterator.next() {
                args += ["-c:v:\(index)", value]
            } else if item == "-b:v", let value = iterator.next() {
                args += ["-b:v:\(index)", value]
            } else if item == "-q:v", let value = iterator.next() {
                args += ["-q:v:\(index)", value]
            } else if item == "-profile:v", let value = iterator.next() {
                args += ["-profile:v:\(index)", value]
            } else if item == "-r", let value = iterator.next() {
                args += ["-filter:v:\(index)", "fps=\(value)"]
            } else if item == "-s", let value = iterator.next() {
                args += ["-filter:v:\(index)", "scale=\(value.replacingOccurrences(of: "x", with: ":"))"]
            } else {
                args.append(item)
            }
        }
    }

    private func appendIndexedAudio(audioArguments: [String], filters: [String], index: String, to args: inout [String]) {
        if !filters.isEmpty {
            args += ["-filter:a:\(index)", ShellQuoting.quote(filters.joined(separator: ","))]
        }
        var iterator = audioArguments.makeIterator()
        while let item = iterator.next() {
            if item == "-c:a", let value = iterator.next() {
                args += ["-c:a:\(index)", value]
            } else if item == "-b:a", let value = iterator.next() {
                args += ["-b:a:\(index)", value]
            } else {
                args.append(item)
            }
        }
    }

    private func appendPlain(_ values: [String], to args: inout [String]) {
        args.append(contentsOf: values)
    }

    private func appendSplit(_ string: String, to args: inout [String]) {
        args.append(contentsOf: ShellQuoting.splitArguments(string))
    }

    private func normalizedOptionName(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("-") { return trimmed }
        return "-" + trimmed
    }

    private func videoQualityArgument(preset: PresetData) -> String? {
        guard !preset.qualityValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        guard let kind = VideoToolboxEncoderKind(encoder: preset.videoEncoder) else {
            return normalizedOptionName(preset.qualityArgumentName)
        }

        switch kind {
        case .h264, .hevc:
            guard let argument = normalizedOptionName(preset.qualityArgumentName) else {
                return "-q:v"
            }
            return argument == "-q:v" ? "-q:v" : nil
        case .prores:
            return nil
        }
    }

    private func appendVideoToolboxQualityOverview(preset: PresetData, to lines: inout [String]) {
        guard let kind = VideoToolboxEncoderKind(encoder: preset.videoEncoder) else { return }

        switch kind {
        case .h264, .hevc:
            if !preset.bitrateBase.isEmpty {
                lines.append("大小控制: -b:v \(preset.bitrateBase)")
            }
            if videoQualityArgument(preset: preset) == "-q:v" {
                lines.append("质量等级: -q:v \(preset.qualityValue)")
            }
        case .prores:
            if !preset.videoProfile.isEmpty {
                lines.append("ProRes 档位: \(preset.videoProfile)")
            }
        }
    }

    private func appendVideoToolboxWarnings(preset: PresetData, to lines: inout [String]) {
        guard let kind = VideoToolboxEncoderKind(encoder: preset.videoEncoder) else { return }

        var ignored: [String] = []
        if !preset.videoPreset.isEmpty { ignored.append("-preset") }
        if !preset.videoTune.isEmpty { ignored.append("-tune") }
        if !preset.videoGPU.isEmpty { ignored.append("-gpu") }
        if !preset.videoThreads.isEmpty { ignored.append("-threads:v") }
        if !ignored.isEmpty {
            lines.append("VideoToolbox 提示: \(ignored.joined(separator: "、")) 不适用，命令生成时已跳过。")
        }

        switch kind {
        case .h264, .hevc:
            if let qualityArgument = normalizedOptionName(preset.qualityArgumentName),
               qualityArgument != "-q:v" {
                if ["-crf", "-cq", "-qp", "-global_quality"].contains(qualityArgument) {
                    lines.append("VideoToolbox 提示: 已跳过 \(qualityArgument)，CRF/CQ/QP 不适用 VideoToolbox。")
                } else {
                    lines.append("VideoToolbox 提示: 已跳过 \(qualityArgument)，VideoToolbox 质量等级仅使用 -q:v。")
                }
            }
        case .prores:
            if !preset.qualityArgumentName.isEmpty || !preset.qualityValue.isEmpty {
                lines.append("ProRes VideoToolbox 提示: 已跳过质量参数，质量/大小请使用 profile 档位。")
            }
        }
    }

    private func extractStreamIndex(_ value: String) -> String {
        value.split(separator: ":").last.map(String.init) ?? value
    }

    private func assColor(_ color: FFColor, alpha: String) -> String {
        let a = Int(alpha) ?? max(0, min(255, 255 - color.alpha))
        return String(format: "&H%02X%02X%02X%02X", a, color.blue, color.green, color.red)
    }

    private func trimFloat(_ value: Float) -> String {
        let double = Double(value)
        if double.rounded() == double {
            return String(Int(double))
        }
        return String(format: "%.3f", double).replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression)
    }

    private func seconds(from time: String) -> TimeInterval? {
        if let value = Double(time) { return value }
        let pieces = time.split(separator: ":")
        guard pieces.count == 3,
              let hours = Double(pieces[0]),
              let minutes = Double(pieces[1]),
              let seconds = Double(pieces[2]) else {
            return nil
        }
        return hours * 3600 + minutes * 60 + seconds
    }

    private func timeString(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = interval - Double(hours * 3600 + minutes * 60)
        return String(format: "%02d:%02d:%05.2f", hours, minutes, seconds)
    }

    private func replacePlaceholders(_ value: String, input: String, output: String) -> String {
        let inputURL = URL(fileURLWithPath: input)
        let inputWithoutExtension = inputURL.deletingPathExtension().path
        let inputDirectory = inputURL.deletingLastPathComponent().path
        return value
            .replacingOccurrences(of: "<InputFile>", with: input)
            .replacingOccurrences(of: "<OutputFile>", with: output)
            .replacingOccurrences(of: "<InputFileWithOutExtension>", with: inputWithoutExtension)
            .replacingOccurrences(of: "<InputFilePath>", with: inputDirectory)
            .replacingOccurrences(of: "<InputFileName>", with: inputURL.lastPathComponent)
            .replacingOccurrences(of: "<InputFileNameWithOutExtension>", with: inputURL.deletingPathExtension().lastPathComponent)
            .replacingOccurrences(of: "<\\InputFileWithOutExtension>", with: ShellQuoting.ffmpegFilterPath(inputWithoutExtension))
            .replacingOccurrences(of: "<\\InputFilePath>", with: ShellQuoting.ffmpegFilterPath(inputDirectory))
    }
}
