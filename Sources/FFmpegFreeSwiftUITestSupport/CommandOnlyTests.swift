import Foundation
import FFmpegFreeSwiftUI

public func makeCommandOnlyTests() -> [TestCase] {
    [
        TestCase("Preset coding", "Partial Chinese keys decode defaults") { _ in
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
        },
        TestCase("Preset coding", "Round trips Chinese keys") { _ in
            var preset = PresetData()
            preset.outputContainer = "mov"
            preset.videoEncoder = "hevc_videotoolbox"
            preset.shaderList = ["/tmp/a.glsl", "/tmp/b.glsl"]
            preset.subtitlePrimaryColor = FFColor(alpha: 10, red: 20, green: 30, blue: 40)
            let data = try PresetIOService.encoder.encode(preset)
            let text = String(data: data, encoding: .utf8) ?? ""
            try expectContains(text, "输出容器", "encoded JSON should contain Chinese output key")
            try expectContains(text, "视频参数_编码器_具体编码", "encoded JSON should contain Chinese encoder key")
            let decoded = try PresetIOService.decoder.decode(PresetData.self, from: data)
            try expectEqual(decoded.outputContainer, "mov", "roundtrip output")
            try expectEqual(decoded.videoEncoder, "hevc_videotoolbox", "roundtrip encoder")
            try expectEqual(decoded.shaderList, ["/tmp/a.glsl", "/tmp/b.glsl"], "roundtrip arrays")
            try expectEqual(decoded.subtitlePrimaryColor, FFColor(alpha: 10, red: 20, green: 30, blue: 40), "roundtrip colors")
        },
        TestCase("Settings coding", "Decodes missing preset auto-load fields") { _ in
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
            try expectEqual(settings.appearanceMode, AppAppearanceMode.system.rawValue, "appearance mode default")
            try expectEqual(settings.interfaceDensity, AppInterfaceDensity.regular.rawValue, "interface density default")
            try expectEqual(settings.baseFontSize, 13, "base font size default")
            try expectEqual(settings.lastPreset.outputContainer, "mp4", "settings last preset")
        },
        TestCase("Settings coding", "Normalizes legacy language values") { _ in
            let zh = try JSONDecoder().decode(AppSettings.self, from: Data(#"{"language":"zh"}"#.utf8))
            let tw = try JSONDecoder().decode(AppSettings.self, from: Data(#"{"language":"zh-TW"}"#.utf8))
            let en = try JSONDecoder().decode(AppSettings.self, from: Data(#"{"language":"en-US"}"#.utf8))
            try expectEqual(zh.language, AppLanguage.simplifiedChinese.rawValue, "legacy zh should become zh-Hans")
            try expectEqual(tw.language, AppLanguage.traditionalChinese.rawValue, "zh-TW should become zh-Hant")
            try expectEqual(en.language, AppLanguage.english.rawValue, "en-US should become en")
        },
        TestCase("Settings coding", "Normalizes display preference values") { _ in
            let valid = try JSONDecoder().decode(AppSettings.self, from: Data(#"{"appearanceMode":"dark","interfaceDensity":"compact","baseFontSize":16}"#.utf8))
            let invalid = try JSONDecoder().decode(AppSettings.self, from: Data(#"{"appearanceMode":"blue","interfaceDensity":"huge","baseFontSize":21}"#.utf8))
            try expectEqual(valid.appearanceMode, AppAppearanceMode.dark.rawValue, "dark appearance")
            try expectEqual(valid.interfaceDensity, AppInterfaceDensity.compact.rawValue, "compact density")
            try expectEqual(valid.baseFontSize, 16, "valid font size")
            try expectEqual(invalid.appearanceMode, AppAppearanceMode.system.rawValue, "invalid appearance defaults to system")
            try expectEqual(invalid.interfaceDensity, AppInterfaceDensity.regular.rawValue, "invalid density defaults to regular")
        },
        TestCase("Localization", "Translates common UI text") { _ in
            try expectEqual(L10n.text("设置", language: "en"), "Settings", "English settings")
            try expectEqual(L10n.text("导航", language: "en"), "Navigation", "English navigation")
            try expectEqual(L10n.text("界面密度", language: "en"), "Interface density", "English interface density")
            try expectEqual(L10n.text("设置", language: "zh-Hant"), "設置", "Traditional Chinese settings")
            try expectEqual(L10n.text("编码队列", language: "zh-Hant"), "編碼隊列", "Traditional Chinese navigation")
            try expectEqual(L10n.text("设置", language: "zh-Hans"), "设置", "Simplified Chinese should keep source text")
        },
        TestCase("FFmpeg locator", "Derives sibling ffprobe and ffplay overrides") { context in
            let directory = context.tempRoot.appendingPathComponent("tools", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            for executable in ["ffmpeg", "ffprobe", "ffplay"] {
                let url = directory.appendingPathComponent(executable)
                try "#!/bin/sh\nexit 0\n".write(to: url, atomically: true, encoding: .utf8)
                try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
            }

            var settings = AppSettings()
            settings.ffmpegExecutableOverride = directory.appendingPathComponent("ffmpeg").path
            let locator = FFmpegLocator(settings: settings)
            try expectEqual(locator.location(for: .ffmpeg).source, .userOverride, "ffmpeg source")
            try expectEqual(locator.locate(.ffprobe), directory.appendingPathComponent("ffprobe").path, "derived ffprobe")
            try expectEqual(locator.locate(.ffplay), directory.appendingPathComponent("ffplay").path, "derived ffplay")
        },
        TestCase("Basic command", "Builds video and audio command") { _ in
            var preset = PresetData()
            preset.outputContainer = "mp4"
            preset.videoEncoder = "libx264"
            preset.videoPreset = "slow"
            preset.qualityArgumentName = "-crf"
            preset.qualityValue = "22"
            preset.audioEncoder = "aac"
            preset.audioBitrate = "192k"
            let built = command(for: preset)
            try expectContains(built, "-hide_banner -nostdin", "basic command banner")
            try expectContains(built, "-i \"/tmp/input file.mkv\"", "quoted input")
            try expectContains(built, "-c:v libx264", "video encoder")
            try expectContains(built, "-preset slow", "preset")
            try expectContains(built, "-crf 22", "quality")
            try expectContains(built, "-c:a aac", "audio encoder")
            try expectContains(built, "-b:a 192k", "audio bitrate")
        },
        TestCase("Basic command", "Normalizes quality argument names") { _ in
            var preset = PresetData()
            preset.videoEncoder = "libx265"
            preset.qualityArgumentName = "cq"
            preset.qualityValue = "28"
            preset.audioQualityArgumentName = "q:a"
            preset.audioQualityValue = "4"
            let built = command(for: preset, input: "/tmp/in.mov", output: "/tmp/out.mp4")
            try expectContains(built, "-cq 28", "video quality argument should be normalized")
            try expectContains(built, "-q:a 4", "audio quality argument should be normalized")
            try expectNotContains(built, " cq ", "bare cq should not appear")
        },
        TestCase("Output settings", "Output path naming and omitted output") { _ in
            var preset = PresetData()
            preset.outputContainer = "mkv"
            preset.useAutoNaming = true
            preset.autoNamingOption = .append3FUI
            preset.outputNamePrefix = "pre_"
            preset.outputNameReplacement = "custom"
            preset.outputNameSuffix = "_done"
            try expectEqual(OutputPathBuilder.build(inputFile: "/tmp/input.mp4", preset: preset), "/tmp/pre_custom_done_3fui.mkv", "output path")

            preset.omitOutputFileArgument = true
            let built = command(for: preset, input: "/tmp/in.mov", output: "/tmp/out.mkv")
            try expectNotContains(built, "/tmp/out.mkv", "omit output should skip output file")
            preset.preserveCreationDate = true
            preset.preserveModificationDate = true
            preset.preserveAccessDate = true
            let dateCommand = command(for: preset, input: "/tmp/in.mov", output: "/tmp/out.mkv")
            try expectNotContains(dateCommand, "preserve", "date preservation is post-processing and should not enter command")
        },
        TestCase("Decoding", "Adds decoder and hardware arguments") { _ in
            var preset = PresetData()
            preset.decoder = "videotoolbox"
            preset.decoderCPUThreads = "4"
            preset.decoderOutputFormat = "videotoolbox"
            preset.decoderHardwareArgumentName = "-hwaccel_device"
            preset.decoderHardwareArgument = "0"
            let built = command(for: preset)
            try expectContains(built, "-hwaccel videotoolbox", "decoder")
            try expectContains(built, "-threads 4", "decoder threads")
            try expectContains(built, "-hwaccel_output_format videotoolbox", "decoder output format")
            try expectContains(built, "-hwaccel_device 0", "decoder hardware argument")
        },
        TestCase("Video encoder", "Adds generic encoder fields") { _ in
            var preset = PresetData()
            preset.videoEncoderCategory = "H.264/AVC"
            preset.videoEncoder = "libx264"
            preset.videoPreset = "medium"
            preset.videoProfile = "high"
            preset.videoTune = "film"
            preset.videoGPU = "0"
            preset.videoThreads = "8"
            let built = command(for: preset)
            try expectContains(built, "-c:v libx264", "video encoder")
            try expectContains(built, "-preset medium", "video preset")
            try expectContains(built, "-profile:v high", "video profile")
            try expectContains(built, "-tune film", "video tune")
            try expectContains(built, "-gpu 0", "video gpu")
            try expectContains(built, "-threads:v 8", "video threads")
            try expectNotContains(built, "H.264/AVC", "category is UI-only")
        },
        TestCase("VideoToolbox", "Capability defaults") { _ in
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
        },
        TestCase("VideoToolbox", "Skips generic encoder options") { _ in
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
            let built = command(for: preset, input: "/tmp/in.mov", output: "/tmp/out.mp4")
            try expectContains(built, "-c:v h264_videotoolbox", "videotoolbox encoder")
            try expectContains(built, "-profile:v high", "videotoolbox profile")
            try expectContains(built, "-pix_fmt nv12", "videotoolbox pix fmt")
            try expectContains(built, "-q:v 60", "videotoolbox q:v")
            try expectContains(built, "-realtime 1", "videotoolbox advanced args")
            try expectNotContains(built, "-preset slow", "videotoolbox should skip preset")
            try expectNotContains(built, "-tune film", "videotoolbox should skip tune")
            try expectNotContains(built, "-gpu 0", "videotoolbox should skip gpu")
            try expectNotContains(built, "-threads:v 8", "videotoolbox should skip video threads")
        },
        TestCase("VideoToolbox", "Probe parser") { _ in
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
        },
        TestCase("Video frame", "Builds frame and transform filters") { _ in
            var preset = PresetData()
            preset.videoResolution = "128x72"
            preset.videoFrameRate = "24"
            preset.videoCrop = "100:60:2:2"
            preset.decimateMaxChangeRatio = "0.10"
            preset.interpolateTargetFPS = "30"
            preset.interpolateMode = "mci"
            preset.interpolateME = "bidir"
            preset.interpolateSearchAlgorithm = "epzs"
            preset.interpolateMCMode = "aobmc"
            preset.interpolateVariableBlock = true
            preset.interpolateBlockSize = "16"
            preset.interpolateSearchRange = "32"
            preset.interpolateSceneChange = "10"
            preset.blendMode = "average"
            preset.blendRatio = "0.5"
            preset.deinterlaceMode = 2
            preset.rotateMode = 1
            preset.mirrorMode = 2
            preset.videoAutoWidth = "640"
            preset.videoAutoHeight = "360"
            let built = command(for: preset)
            try expectContains(built, "-s 128x72", "resolution")
            try expectContains(built, "-r 24", "frame rate")
            try expectContains(built, "crop=100:60:2:2", "crop filter")
            try expectContains(built, "mpdecimate=frac=0.10", "decimate filter")
            try expectContains(built, "minterpolate=fps=30:mi_mode=mci:me_mode=bidir:me=epzs:mc_mode=aobmc:vsbmc=1:mb_size=16:search_param=32:scd_threshold=10", "interpolation filter")
            try expectContains(built, "tblend=all_mode=average:opacity=0.5", "blend filter")
            try expectContains(built, "yadif=0:0:0", "deinterlace filter")
            try expectContains(built, "transpose=1", "rotate filter")
            try expectContains(built, "vflip", "mirror filter")
            try expectNotContains(built, "640", "auto width is not currently emitted")
            try expectNotContains(built, "360", "auto height is not currently emitted")
        },
        TestCase("Video quality", "Builds quality and bitrate arguments") { _ in
            var preset = PresetData()
            preset.bitrateControlMode = "VBR"
            preset.qualityArgumentName = "-crf"
            preset.qualityValue = "23"
            preset.bitrateBase = "1200k"
            preset.bitrateMin = "600k"
            preset.bitrateMax = "1600k"
            preset.bitrateBuffer = "2400k"
            preset.advancedQualityArguments = ["-x264-params", "keyint=48"]
            let built = command(for: preset)
            try expectContains(built, "-crf 23", "quality")
            try expectContains(built, "-b:v 1200k", "bitrate base")
            try expectContains(built, "-minrate 600k", "minrate")
            try expectContains(built, "-maxrate 1600k", "maxrate")
            try expectContains(built, "-bufsize 2400k", "bufsize")
            try expectContains(built, "-x264-params keyint=48", "advanced quality")
            try expectNotContains(built, "VBR", "bitrate control label is UI-only")
        },
        TestCase("Color", "Builds pixel format color and eq filters") { _ in
            var preset = PresetData()
            preset.videoEncoder = "libx264"
            preset.pixelFormat = "yuv420p"
            preset.colorFilter = "zscale"
            preset.colorMatrix = "bt709"
            preset.colorPrimaries = "bt709"
            preset.colorTransfer = "bt709"
            preset.colorRange = "tv"
            preset.tonemapAlgorithm = "clip"
            preset.colorProcessMode = "仅转换"
            preset.brightness = "0.1"
            preset.contrast = "1.2"
            preset.saturation = "1.1"
            preset.gamma = "0.9"
            let built = command(for: preset)
            try expectContains(built, "format=yuv420p", "software pixel format filter")
            try expectContains(built, "zscale=matrix=bt709:primaries=bt709:transfer=bt709:range=tv:tonemap=clip", "color filter")
            try expectContains(built, "eq=brightness=0.1:contrast=1.2:saturation=1.1:gamma=0.9", "eq filter")
            try expectNotContains(built, "仅转换", "color process mode is not currently emitted")
        },
        TestCase("Common filters", "Builds denoise sharpen and subtitle burn") { _ in
            var preset = PresetData()
            preset.denoiseMode = "hqdn3d"
            preset.denoiseParameter1 = "1"
            preset.denoiseParameter2 = "2"
            preset.denoiseParameter3 = "3"
            preset.denoiseParameter4 = "4"
            preset.sharpenWidth = "3"
            preset.sharpenHeight = "3"
            preset.sharpenStrength = "0.8"
            preset.subtitleExternalSource = true
            preset.subtitleBurnFilter = "subtitles"
            preset.externalSubtitleDirectory = "/tmp"
            preset.externalSubtitleFileName = "sub.ass"
            preset.subtitleFontsDirectory = "/tmp/fonts"
            preset.subtitleStyleName = "Arial"
            preset.subtitleStyleSize = 18
            preset.subtitleBold = true
            preset.subtitleItalic = true
            preset.subtitleUnderline = true
            preset.subtitleStrikeout = true
            preset.subtitleBorderStyle = 1
            preset.subtitleOutlineWidth = "2"
            preset.subtitleShadowDistance = "1"
            preset.subtitlePrimaryColor = FFColor(alpha: 0, red: 255, green: 255, blue: 255)
            preset.subtitlePrimaryAlpha = "20"
            preset.subtitleAlignment = 2
            preset.subtitleMarginV = "12"
            preset.subtitleMarginL = "10"
            preset.subtitleMarginR = "10"
            preset.subtitleSpacing = "0.5"
            preset.subtitleLineSpacing = "1"
            preset.subtitleResolution = "1920x1080"
            preset.subtitleCustomStyle = "OutlineColour=&H00000000"
            preset.subtitleCustomFilterArguments = "charenc=UTF-8"
            let built = command(for: preset, input: "/tmp/in.mkv", output: "/tmp/out.mp4")
            try expectContains(built, "hqdn3d=1:2:3:4", "denoise")
            try expectContains(built, "unsharp=3:3:0.8", "sharpen")
            try expectContains(built, "subtitles=", "subtitle burn filter")
            try expectContains(built, "sub.ass", "external subtitle")
            try expectContains(built, "fontsdir=", "subtitle fonts")
            try expectContains(built, "FontName=Arial", "subtitle style name")
            try expectContains(built, "FontSize=18", "subtitle style size")
            try expectContains(built, "Bold=1", "subtitle bold")
            try expectContains(built, "Italic=1", "subtitle italic")
            try expectContains(built, "Underline=1", "subtitle underline")
            try expectContains(built, "StrikeOut=1", "subtitle strikeout")
            try expectContains(built, "BorderStyle=1", "subtitle border style")
            try expectContains(built, "PrimaryColour=&H14FFFFFF", "subtitle primary color")
            try expectContains(built, "Alignment=2", "subtitle alignment")
            try expectContains(built, "charenc=UTF-8", "subtitle custom filter arguments")
            try expectNotContains(built, "1920x1080", "subtitle resolution is not currently emitted")
        },
        TestCase("Frame server", "Switches input path for script modes") { _ in
            var avs = PresetData()
            avs.useAviSynth = true
            avs.aviSynthScript = "/tmp/template.avs"
            let avsCommand = command(for: avs, input: "/tmp/source.mkv", output: "/tmp/out.mp4")
            try expectContains(avsCommand, "-i /tmp/source.avs", "AviSynth input")
            try expectNotContains(avsCommand, "template.avs", "AviSynth script template is not directly emitted")

            var vpy = PresetData()
            vpy.useVapourSynth = true
            vpy.vapourSynthScript = "/tmp/template.vpy"
            let vpyCommand = command(for: vpy, input: "/tmp/source.mkv", output: "/tmp/out.mp4")
            try expectContains(vpyCommand, "-f vapoursynth -i /tmp/source.vpy", "VapourSynth input")
        },
        TestCase("Audio", "Builds encoder quality channel sample-rate and loudnorm") { _ in
            var preset = PresetData()
            preset.audioEncoder = "aac"
            preset.audioBitrate = "128k"
            preset.audioQualityArgumentName = "q:a"
            preset.audioQualityValue = "2"
            preset.audioChannels = "2"
            preset.audioSampleRate = "48000"
            preset.loudnormTarget = "-23"
            preset.loudnormRange = "7"
            preset.loudnormPeak = "-1"
            let built = command(for: preset)
            try expectContains(built, "-c:a aac", "audio encoder")
            try expectContains(built, "-b:a 128k", "audio bitrate")
            try expectContains(built, "-q:a 2", "audio quality")
            try expectContains(built, "-ac 2", "audio channels")
            try expectContains(built, "-ar 48000", "audio sample rate")
            try expectContains(built, "-af loudnorm=I=-23:LRA=7:TP=-1", "loudnorm")
        },
        TestCase("Audio", "Disables audio") { _ in
            var preset = PresetData()
            preset.audioEncoder = "禁用"
            let built = command(for: preset)
            try expectContains(built, "-an", "disable audio")
        },
        TestCase("Image", "Builds image encoder and quality") { _ in
            var preset = PresetData()
            preset.imageEncoder = "png"
            preset.imageQuality = "3"
            let built = command(for: preset, input: "/tmp/in.mov", output: "/tmp/out.png")
            try expectContains(built, "-c:v png", "image encoder")
            try expectContains(built, "-q:v 3", "image quality")
        },
        TestCase("Custom arguments", "Adds all custom argument positions") { _ in
            var preset = PresetData()
            preset.customLeadingArguments = "-loglevel warning"
            preset.customBeforeOutputArguments = "-stream_loop 1 -i /tmp/overlay.mov"
            preset.customVideoFilter = "scale=64:64"
            preset.customAudioFilter = "volume=0.5"
            preset.customVideoArguments = "-tag:v avc1"
            preset.customAudioArguments = "-strict -2"
            preset.customAfterOutputArguments = "-movflags +faststart"
            preset.customTrailingArguments = "-report"
            let built = command(for: preset, input: "/tmp/in.mov", output: "/tmp/out.mp4")
            try expectContains(built, "-loglevel warning", "leading args")
            try expectContains(built, "-stream_loop 1 -i /tmp/overlay.mov", "before output args")
            try expectContains(built, "-vf scale=64:64", "custom video filter")
            try expectContains(built, "-af volume=0.5", "custom audio filter")
            try expectContains(built, "-tag:v avc1", "custom video args")
            try expectContains(built, "-strict -2", "custom audio args")
            try expectContains(built, "-movflags +faststart", "after output args")
            try expectContains(built, "-report", "trailing args")
        },
        TestCase("Custom arguments", "Full custom replaces placeholders") { _ in
            var preset = PresetData()
            preset.customFullArguments = "-i <InputFile> -map 0 <OutputFile> <InputFileName> <InputFileNameWithOutExtension> <InputFileWithOutExtension> <InputFilePath>"
            let built = command(for: preset, input: "/tmp/a b/source.mov", output: "/tmp/out.mp4")
            try expectEqual(built, "-i /tmp/a b/source.mov -map 0 /tmp/out.mp4 source.mov source /tmp/a b/source /tmp/a b", "full custom placeholders")
        },
        TestCase("Custom arguments", "Filter complex replaces simple filters") { _ in
            var preset = PresetData()
            preset.customVideoFilter = "scale=64:64"
            preset.customAudioFilter = "volume=0.5"
            preset.customFilterComplex = "[0:v]scale=64:64[v]"
            let built = command(for: preset)
            try expectContains(built, "-filter_complex [0:v]scale=64:64[v]", "filter complex")
            try expectNotContains(built, "-vf scale=64:64", "filter complex should suppress simple vf")
            try expectNotContains(built, "-af volume=0.5", "filter complex should suppress simple af")
        },
        TestCase("Clip", "Builds rough precise and preseek clipping") { _ in
            var rough = PresetData()
            rough.clipMethod = .rough
            rough.clipInPoint = "00:00:02.00"
            rough.clipOutPoint = "00:00:03.00"
            let roughCommand = command(for: rough)
            try expectContains(roughCommand, "-ss 00:00:02.00 -to 00:00:03.00 -i", "rough clip before input")

            var precise = PresetData()
            precise.clipMethod = .preciseFromStart
            precise.clipInPoint = "00:00:01.00"
            precise.clipOutPoint = "00:00:02.00"
            let preciseCommand = command(for: precise)
            try expectContains(preciseCommand, "-ss 00:00:01.00 -to 00:00:02.00", "precise clip after output options")

            var preseek = PresetData()
            preseek.clipMethod = .preciseWithPreseek
            preseek.clipInPoint = "00:00:10.00"
            preseek.clipPreDecodeSeconds = "2"
            let preseekCommand = command(for: preseek)
            try expectContains(preseekCommand, "-ss 00:00:08.00 -i", "preseek clip")
        },
        TestCase("Stream control", "Indexes video and audio parameters") { _ in
            var preset = PresetData()
            preset.keepOtherVideoStreams = true
            preset.videoStreamTargets = ["0:v:1"]
            preset.keepOtherAudioStreams = true
            preset.audioStreamTargets = ["0:a:0"]
            preset.videoEncoder = "libx265"
            preset.audioEncoder = "libopus"
            let built = command(for: preset, input: "/tmp/in.mkv", output: "/tmp/out.mkv")
            try expectContains(built, "-map 0:v? -c:v copy", "video stream copy")
            try expectContains(built, "-c:v:1 libx265", "indexed video encoder")
            try expectContains(built, "-map 0:a? -c:a copy", "audio stream copy")
            try expectContains(built, "-c:a:0 libopus", "indexed audio encoder")
        },
        TestCase("Stream control", "Builds subtitle metadata chapter attachment options") { _ in
            var preset = PresetData()
            preset.subtitleStreamTargets = ["0:s:0"]
            preset.subtitleOperation = 2
            preset.keepOtherSubtitleStreams = true
            preset.autoMuxSubtitleToMovText = true
            preset.metadataOption = 2
            preset.chapterOption = 1
            preset.attachmentOption = 1
            let built = command(for: preset, input: "/tmp/in.mkv", output: "/tmp/out.mkv")
            try expectContains(built, "-map 0:s? -c:s copy", "keep subtitle streams")
            try expectContains(built, "-map 0:s:0?", "subtitle target")
            try expectContains(built, "-c:s mov_text", "subtitle operation")
            try expectContains(built, "-map_metadata -1", "metadata clear")
            try expectContains(built, "-map_chapters 0", "chapters keep")
            try expectContains(built, "-map 0:t?", "attachments keep")
        },
        TestCase("Auto mux", "Adds sidecar subtitle inputs when files exist") { context in
            let input = context.tempRoot.appendingPathComponent("movie.mkv")
            let srt = context.tempRoot.appendingPathComponent("movie.srt")
            let ass = context.tempRoot.appendingPathComponent("movie.ass")
            let ssa = context.tempRoot.appendingPathComponent("movie.ssa")
            FileManager.default.createFile(atPath: input.path, contents: Data())
            FileManager.default.createFile(atPath: srt.path, contents: Data())
            FileManager.default.createFile(atPath: ass.path, contents: Data())
            FileManager.default.createFile(atPath: ssa.path, contents: Data())
            var preset = PresetData()
            preset.autoMuxSRT = true
            preset.autoMuxASS = true
            preset.autoMuxSSA = true
            let built = command(for: preset, input: input.path, output: context.tempRoot.appendingPathComponent("out.mkv").path)
            try expectContains(built, "-i \(srt.path)", "auto mux srt")
            try expectContains(built, "-i \(ass.path)", "auto mux ass")
            try expectContains(built, "-i \(ssa.path)", "auto mux ssa")
        },
        TestCase("Progress parser", "Parses duration and progress line") { _ in
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
        },
        TestCase("Progress parser", "Ignores placeholder quality") { _ in
            var progress = EncodingProgress()
            progress.quality = "N/A"
            let parser = FFmpegProgressParser()
            try expect(parser.parse(line: "frame=   30 fps=0.0 q=-0.0 Lsize=N/A time=00:00:00.96 bitrate=N/A speed=9.34x", into: &progress, startedAt: Date()), "placeholder quality line should parse")
            try expectEqual(progress.quality, "N/A", "placeholder q should not replace quality")
            try expect(parser.parse(line: "frame=  100 fps=25 q=23.0 size=    2048KiB time=00:01:00.00 bitrate=1200.0kbits/s speed=2.0x", into: &progress, startedAt: Date()), "real quality line should parse")
            try expectEqual(progress.quality, "23.0", "real q should replace quality")
        },
        TestCase("Shell", "Splits quoted command") { _ in
            try expectEqual(ShellQuoting.splitArguments("-i \"/tmp/a b.mov\" -c:v libx264"), ["-i", "/tmp/a b.mov", "-c:v", "libx264"], "shell split")
        },
        TestCase("Scheme management", "Settings persist preset auto-load choices") { _ in
            var settings = AppSettings()
            settings.presetAutoLoadMode = 2
            settings.presetAutoLoadPath = "/tmp/preset.3fui"
            let data = try JSONEncoder().encode(settings)
            let decoded = try JSONDecoder().decode(AppSettings.self, from: data)
            try expectEqual(decoded.presetAutoLoadMode, 2, "preset auto load mode")
            try expectEqual(decoded.presetAutoLoadPath, "/tmp/preset.3fui", "preset auto load path")
        },
        TestCase("Muxing", "Builds mapped copy command") { _ in
            let inputs = [
                MuxingInput(path: "/tmp/a file.mkv", videoStreams: "0,1", audioStreams: "0", subtitleStreams: "", usesChapters: true),
                MuxingInput(path: "/tmp/b.mka", audioStreams: "0", subtitleStreams: "0", usesMetadata: true)
            ]
            let built = MuxingCommandBuilder().build(inputs: inputs, output: "/tmp/out file.mkv")
            try expectContains(built, "-i \"/tmp/a file.mkv\"", "first input")
            try expectContains(built, "-map 0:v:0 -c:v copy", "video map 0")
            try expectContains(built, "-map 0:v:1 -c:v copy", "video map 1")
            try expectContains(built, "-map 0:a:0 -c:a copy", "audio map 0")
            try expectContains(built, "-map_chapters 0", "chapters")
            try expectContains(built, "-map 1:a:0 -c:a copy", "second audio map")
            try expectContains(built, "-map 1:s:0 -c:s copy", "subtitle map")
            try expectContains(built, "-map_metadata 1", "metadata")
            try expectContains(built, "\"/tmp/out file.mkv\" -y", "output")
        },
        TestCase("Merging", "Builds concat demuxer command and body") { _ in
            let builder = MergingCommandBuilder()
            let body = builder.concatFileBody(files: ["/tmp/a file.mp4", "/tmp/quote's.mp4"])
            try expectContains(body, "file '/tmp/a file.mp4'", "concat first file")
            try expectContains(body, "file '/tmp/quote'\\''s.mp4'", "concat quote escaping")
            let built = builder.build(concatFile: "/tmp/list file.txt", output: "/tmp/out file.mp4")
            try expectContains(built, "-f concat -safe 0 -i \"/tmp/list file.txt\" -c copy \"/tmp/out file.mp4\" -y", "concat command")
        },
        TestCase("Quality assessment", "Builds metric commands") { context in
            let config = QualityAssessmentConfiguration(
                startTime: "00:00:01",
                duration: "5",
                outputDirectory: "",
                vmafModel: "/tmp/model.json",
                vmafPool: "harmonic_mean",
                sampleInterval: "3"
            )
            let command = QualityAssessmentRunner.command(
                metric: .vmaf,
                referenceFile: "/tmp/ref file.mp4",
                distortedFile: "/tmp/dist.mp4",
                configuration: config,
                logDirectory: context.tempRoot
            )
            let line = command.argumentsLine
            try expectContains(line, "-ss 00:00:01 -t 5", "start and duration")
            try expectContains(line, "-i /tmp/dist.mp4 -i \"/tmp/ref file.mp4\"", "inputs")
            try expectContains(line, "-filter_complex", "sampled vmaf uses filter complex")
            try expectContains(line, "libvmaf=", "vmaf filter")
            try expectContains(line, "log_fmt=json", "vmaf json")
            try expectContains(line, "model_path=", "vmaf model")
            try expectContains(line, "pool=harmonic_mean", "vmaf pool")
        },
        TestCase("Quality assessment", "Parses PSNR SSIM and VMAF results") { _ in
            let psnr = QualityAssessmentRunner.parseResult(
                metric: .psnr,
                output: "[Parsed_psnr_0] PSNR y:40.1 u:42.0 v:43.0 average:41.5 min:35.2 max:inf",
                logPath: "/tmp/missing.log",
                referenceFile: "/tmp/ref.mp4",
                distortedFile: "/tmp/dist.mp4",
                elapsedSeconds: 1
            )
            try expectEqual(psnr.score, "41.5", "psnr average")
            try expectEqual(psnr.minimum, "35.2", "psnr minimum")

            let ssim = QualityAssessmentRunner.parseResult(
                metric: .ssim,
                output: "[Parsed_ssim_0] SSIM Y:0.98 U:0.99 V:0.99 All:0.987 (18.8)",
                logPath: "/tmp/missing.log",
                referenceFile: "/tmp/ref.mp4",
                distortedFile: "/tmp/dist.mp4",
                elapsedSeconds: 1
            )
            try expectEqual(ssim.score, "0.987", "ssim all")

            let vmaf = QualityAssessmentRunner.parseResult(
                metric: .vmaf,
                output: #"{ "pooled_metrics": { "vmaf": { "min": 91.2, "mean": 95.4 } } }"#,
                logPath: "/tmp/missing.json",
                referenceFile: "/tmp/ref.mp4",
                distortedFile: "/tmp/dist.mp4",
                elapsedSeconds: 1
            )
            try expectEqual(vmaf.score, "95.4", "vmaf mean")
            try expectEqual(vmaf.minimum, "91.2", "vmaf min")
        },
        TestCase("Performance", "Collects nonblocking snapshot") { _ in
            let monitor = PerformanceMonitor()
            let semaphore = DispatchSemaphore(value: 0)
            final class Box: @unchecked Sendable { var snapshot: PerformanceSnapshot? }
            let box = Box()
            Task {
                box.snapshot = await monitor.snapshot(runningQueueTasks: 1, pendingQueueTasks: 2)
                semaphore.signal()
            }
            guard semaphore.wait(timeout: .now() + 5) == .success, let snapshot = box.snapshot else {
                throw TestFailure("performance snapshot timed out")
            }
            try expect(snapshot.coreUsages.count >= 1, "core usages should be present")
            try expect(snapshot.memoryTotalBytes > 0, "memory total should be present")
            try expectEqual(snapshot.runningQueueTasks, 1, "running queue count")
            try expectEqual(snapshot.pendingQueueTasks, 2, "pending queue count")
        }
    ]
}
