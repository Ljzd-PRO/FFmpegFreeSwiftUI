import SwiftUI

func normalizeOptionNameInput(_ value: String) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, !trimmed.hasPrefix("-") else { return trimmed }
    return "-" + trimmed
}

struct OverviewPane: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @Binding var preset: PresetData
    private let builder = FFmpegCommandBuilder()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(t("参数总览"))
                .font(.title2.weight(.semibold))
            Text(builder.overview(preset: preset))
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
            Text(t("实际命令行"))
                .font(.headline)
            Text(builder.build(preset: preset, input: "<InputFile>", output: "<OutputFile>"))
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
    }

    private func t(_ key: String) -> String {
        L10n.text(key, language: settingsStore.settings.language)
    }
}

struct OutputSettingsPane: View {
    @Binding var preset: PresetData

    var body: some View {
        FormSection(title: "输出文件设置", note: "这些功能在任务结束时由 3FUI 进行处理，与 ffmpeg 无关。") {
            FormRow(label: "输出容器", help: ParameterOptionCatalog.outputContainer.help) {
                FieldComboBox(text: $preset.outputContainer, info: ParameterOptionCatalog.outputContainer)
            }
            FormRow(label: "输出位置", help: ParameterOptionCatalog.outputLocation.help) {
                FieldComboBox(text: $preset.outputLocation, info: ParameterOptionCatalog.outputLocation)
            }
            FormRow(label: "不附加输出文件参数", help: "特殊用途，新手勿用；开启后命令不会自动写入输出文件路径。") { Toggle("", isOn: $preset.omitOutputFileArgument) }
            FormRow(label: "使用自动命名", help: "关闭不影响自定义开头、替代、结尾文本。") { Toggle("", isOn: $preset.useAutoNaming) }
            FormRow(label: "自动命名选项", help: "选择自动命名方法。") {
                MappedOptionComboBox(selection: $preset.autoNamingOption, placeholder: "", options: ParameterOptionCatalog.autoNamingOptions)
            }
            FormRow(label: "开头文本") { FieldComboBox(text: $preset.outputNamePrefix, info: ParameterOptionCatalog.outputPrefix) }
            FormRow(label: "替代文本") { FieldComboBox(text: $preset.outputNameReplacement, info: ParameterOptionCatalog.outputReplacement) }
            FormRow(label: "结尾文本") { FieldComboBox(text: $preset.outputNameSuffix, info: ParameterOptionCatalog.outputSuffix) }
            FormRow(label: "文件时间", help: "按输入文件同步输出文件的时间属性；创建时间在 macOS 不可写时会自动跳过。") {
                HStack {
                    Toggle("创建", isOn: $preset.preserveCreationDate)
                    Toggle("修改", isOn: $preset.preserveModificationDate)
                    Toggle("访问", isOn: $preset.preserveAccessDate)
                }
            }
        }
    }
}

struct DecodingPane: View {
    @Binding var preset: PresetData

    var body: some View {
        FormSection(title: "解码设置", note: "如果你不知道要设置成什么，就不要设置！本页所有设置都是如此！\ncuda = NVIDIA   qsv = Intel   amf = AMD") {
            FormRow(label: "解码器", help: ParameterOptionCatalog.decoder.help) {
                FieldComboBox(text: $preset.decoder, info: ParameterOptionCatalog.decoder)
            }
            FormRow(label: "CPU 解码线程数", help: ParameterOptionCatalog.decoderThreads.help) {
                FieldComboBox(text: $preset.decoderCPUThreads, info: ParameterOptionCatalog.decoderThreads)
            }
            FormRow(label: "解码数据格式", help: ParameterOptionCatalog.decoderOutputFormat.help) {
                FieldComboBox(text: $preset.decoderOutputFormat, info: ParameterOptionCatalog.decoderOutputFormat)
            }
            FormRow(label: "指定硬件参数名", help: ParameterOptionCatalog.decoderHardwareArgumentName.help) {
                FieldComboBox(text: $preset.decoderHardwareArgumentName, info: ParameterOptionCatalog.decoderHardwareArgumentName)
            }
            FormRow(label: "指定硬件参数", help: ParameterOptionCatalog.decoderHardwareArgument.help) {
                FieldComboBox(text: $preset.decoderHardwareArgument, info: ParameterOptionCatalog.decoderHardwareArgument)
            }
        }
    }
}

struct VideoEncoderPane: View {
    @Binding var preset: PresetData
    var probedCapabilities: [String: VideoEncoderCapability]

    private var profile: VideoEncoderProfile {
        ParameterOptionCatalog.profile(for: preset.videoEncoder, probedCapabilities: probedCapabilities)
    }

    private var sectionNote: String {
        switch VideoToolboxEncoderKind(encoder: preset.videoEncoder) {
        case .h264:
            return "H.264 VideoToolbox 兼容性最好，适合发给别人或上传平台。它不支持 x264/x265 的 preset/tune/CRF 语义。"
        case .hevc:
            return "HEVC VideoToolbox 同等观感下通常比 H.264 更省体积，适合较新设备。建议 MP4 输出搭配 -tag:v hvc1。"
        case .prores:
            return "ProRes VideoToolbox 适合剪辑中间文件，文件会很大，不适合压小视频；质量/大小主要由 profile 档位决定。"
        case .none:
            return "视频编码器通用配置；部分编码器的参数名有区别，会自动使用对应参数名。以上三个参数还有很多值尚未收录，欢迎反馈补充和修正。"
        }
    }

    var body: some View {
        FormSection(title: "视频参数编码器", note: sectionNote) {
            FormRow(label: "类别", help: ParameterOptionCatalog.videoEncoderCategory.help) {
                FieldComboBox(text: $preset.videoEncoderCategory, info: ParameterOptionCatalog.videoEncoderCategory)
            }
            FormRow(label: "具体编码", help: ParameterOptionCatalog.videoEncoder.help) {
                FieldComboBox(text: $preset.videoEncoder, info: ParameterOptionCatalog.videoEncoder, options: ParameterOptionCatalog.videoEncoders(for: preset.videoEncoderCategory))
            }
            FormRow(label: "编码预设", help: ParameterOptionCatalog.presetInfo(for: preset.videoEncoder).help) {
                FieldComboBox(text: $preset.videoPreset, info: ParameterOptionCatalog.presetInfo(for: preset.videoEncoder), options: profile.presets)
            }
            FormRow(label: "配置文件", help: ParameterOptionCatalog.profileInfo(for: preset.videoEncoder).help) {
                FieldComboBox(text: $preset.videoProfile, info: ParameterOptionCatalog.profileInfo(for: preset.videoEncoder), options: profile.profiles)
            }
            FormRow(label: "场景优化", help: ParameterOptionCatalog.tuneInfo(for: preset.videoEncoder).help) {
                FieldComboBox(text: $preset.videoTune, info: ParameterOptionCatalog.tuneInfo(for: preset.videoEncoder), options: profile.tunes)
            }
            FormRow(label: "GPU", help: ParameterOptionCatalog.gpuInfo(for: preset.videoEncoder).help) {
                FieldComboBox(text: $preset.videoGPU, info: ParameterOptionCatalog.gpuInfo(for: preset.videoEncoder))
            }
            FormRow(label: "threads", help: ParameterOptionCatalog.threadsInfo(for: preset.videoEncoder).help) {
                FieldComboBox(text: $preset.videoThreads, info: ParameterOptionCatalog.threadsInfo(for: preset.videoEncoder))
            }
        }
    }
}

struct VideoFramePane: View {
    @Binding var preset: PresetData

    var body: some View {
        FormSection(title: "视频参数画面帧", note: "指定帧率、分辨率、裁剪和扫描方式；如果不确定就保持空白。") {
            FormRow(label: "分辨率", help: ParameterOptionCatalog.resolution.help) { FieldComboBox(text: $preset.videoResolution, info: ParameterOptionCatalog.resolution) }
            FormRow(label: "自动宽度", help: ParameterOptionCatalog.autoWidth.help) { FieldComboBox(text: $preset.videoAutoWidth, info: ParameterOptionCatalog.autoWidth) }
            FormRow(label: "自动高度", help: ParameterOptionCatalog.autoHeight.help) { FieldComboBox(text: $preset.videoAutoHeight, info: ParameterOptionCatalog.autoHeight) }
            FormRow(label: "裁剪滤镜参数", help: ParameterOptionCatalog.crop.help) { FieldComboBox(text: $preset.videoCrop, info: ParameterOptionCatalog.crop) }
            FormRow(label: "帧速率", help: ParameterOptionCatalog.frameRate.help) { FieldComboBox(text: $preset.videoFrameRate, info: ParameterOptionCatalog.frameRate) }
            FormRow(label: "抽帧最大变化比例", help: ParameterOptionCatalog.decimateRatio.help) { FieldComboBox(text: $preset.decimateMaxChangeRatio, info: ParameterOptionCatalog.decimateRatio) }
            FormRow(label: "插帧目标帧率") { FieldComboBox(text: $preset.interpolateTargetFPS, info: ParameterOptionCatalog.targetFPS) }
            FormRow(label: "帧混合指定帧率") { FieldComboBox(text: $preset.blendTargetFPS, info: ParameterOptionCatalog.targetFPS) }
            FormRow(label: "逐行与隔行", help: "选择扫描方式；当前 macOS 首版命令生成支持前 3 种 yadif 基础模式，其他选项保留原版入口。") {
                MappedOptionComboBox(selection: $preset.deinterlaceMode, placeholder: "选择操作", options: ParameterOptionCatalog.deinterlaceModes)
            }
            FormRow(label: "角度翻转") {
                MappedOptionComboBox(selection: $preset.rotateMode, placeholder: "角度翻转", options: ParameterOptionCatalog.rotateModes)
            }
            FormRow(label: "镜像翻转") {
                MappedOptionComboBox(selection: $preset.mirrorMode, placeholder: "镜像翻转", options: ParameterOptionCatalog.mirrorModes)
            }
        }
    }
}

struct VideoQualityPane: View {
    @Binding var preset: PresetData
    var probedCapabilities: [String: VideoEncoderCapability]

    private var sectionNote: String {
        switch VideoToolboxEncoderKind(encoder: preset.videoEncoder) {
        case .h264, .hevc:
            return "VideoToolbox 控制大小优先填 -b:v；不想计算大小可用 -q:v 65。大小可粗略估算为：码率 Mbps × 时长分钟 × 7.5。"
        case .prores:
            return "ProRes 不适合压小文件，优先在编码器页选择 profile 档位：proxy < lt < standard < hq < 4444 < xq。"
        case .none:
            return "传统的转码直接指定数据速率；对于压制工作通常不考虑。基础比特率与全局质量控制可能冲突。"
        }
    }

    var body: some View {
        FormSection(title: "视频参数质量", note: sectionNote) {
            FormRow(label: "控制方式", help: ParameterOptionCatalog.bitrateControlInfo(for: preset.videoEncoder, probedCapabilities: probedCapabilities).help) {
                FieldComboBox(text: $preset.bitrateControlMode, info: ParameterOptionCatalog.bitrateControlInfo(for: preset.videoEncoder, probedCapabilities: probedCapabilities))
            }
            FormRow(label: "质量参数名", help: ParameterOptionCatalog.qualityArgumentInfo(for: preset.videoEncoder, probedCapabilities: probedCapabilities).help) {
                FieldComboBox(text: $preset.qualityArgumentName, info: ParameterOptionCatalog.qualityArgumentInfo(for: preset.videoEncoder, probedCapabilities: probedCapabilities), normalize: normalizeOptionNameInput)
            }
            FormRow(label: "质量值", help: ParameterOptionCatalog.qualityValueInfo(for: preset.videoEncoder, probedCapabilities: probedCapabilities).help) {
                FieldComboBox(text: $preset.qualityValue, info: ParameterOptionCatalog.qualityValueInfo(for: preset.videoEncoder, probedCapabilities: probedCapabilities))
            }
            FormRow(label: "比特率基础", help: ParameterOptionCatalog.bitrateBase.help) {
                FieldComboBox(text: $preset.bitrateBase, info: ParameterOptionCatalog.bitrateBase)
            }
            FormRow(label: "最低值") {
                FieldComboBox(text: $preset.bitrateMin, info: ParameterOptionCatalog.bitrateMin)
            }
            FormRow(label: "最高值", help: ParameterOptionCatalog.bitrateMax.help) {
                FieldComboBox(text: $preset.bitrateMax, info: ParameterOptionCatalog.bitrateMax)
            }
            FormRow(label: "缓冲区", help: ParameterOptionCatalog.bitrateBuffer.help) {
                FieldComboBox(text: $preset.bitrateBuffer, info: ParameterOptionCatalog.bitrateBuffer)
            }
            FormRow(label: "进阶参数集", help: ParameterOptionCatalog.advancedQualityInfo(for: preset.videoEncoder, probedCapabilities: probedCapabilities).help) {
                FieldComboBox(text: stringArrayBinding($preset.advancedQualityArguments), info: ParameterOptionCatalog.advancedQualityInfo(for: preset.videoEncoder, probedCapabilities: probedCapabilities))
            }
        }
    }
}

struct ColorPane: View {
    @Binding var preset: PresetData
    var probedCapabilities: [String: VideoEncoderCapability]

    private var pixelFormats: [ParameterOption] {
        let encoderFormats = ParameterOptionCatalog.profile(for: preset.videoEncoder, probedCapabilities: probedCapabilities).pixelFormats
        return encoderFormats.isEmpty ? ParameterOptionCatalog.pixelFormat.options : encoderFormats
    }

    var body: some View {
        FormSection(title: "视频参数色彩管理", note: "虽然不强制要求全部设置，但滤镜可能有自己的逻辑。高级调色建议使用专业调色软件，这里可以不全部设置。") {
            FormRow(label: "像素格式", help: ParameterOptionCatalog.pixelFormat.help) {
                FieldComboBox(text: $preset.pixelFormat, info: ParameterOptionCatalog.pixelFormat, options: pixelFormats)
            }
            FormRow(label: "滤镜选择", help: ParameterOptionCatalog.colorFilter.help) {
                FieldComboBox(text: $preset.colorFilter, info: ParameterOptionCatalog.colorFilter)
            }
            FormRow(label: "矩阵系数", help: ParameterOptionCatalog.colorMatrix.help) {
                FieldComboBox(text: $preset.colorMatrix, info: ParameterOptionCatalog.colorMatrix)
            }
            FormRow(label: "色域", help: ParameterOptionCatalog.colorPrimaries.help) {
                FieldComboBox(text: $preset.colorPrimaries, info: ParameterOptionCatalog.colorPrimaries)
            }
            FormRow(label: "传输特性", help: ParameterOptionCatalog.colorTransfer.help) {
                FieldComboBox(text: $preset.colorTransfer, info: ParameterOptionCatalog.colorTransfer)
            }
            FormRow(label: "范围", help: ParameterOptionCatalog.colorRange.help) {
                FieldComboBox(text: $preset.colorRange, info: ParameterOptionCatalog.colorRange)
            }
            FormRow(label: "色调映射算法", help: ParameterOptionCatalog.tonemap.help) {
                FieldComboBox(text: $preset.tonemapAlgorithm, info: ParameterOptionCatalog.tonemap)
            }
            FormRow(label: "处理方式", help: ParameterOptionCatalog.colorProcess.help) {
                FieldComboBox(text: $preset.colorProcessMode, info: ParameterOptionCatalog.colorProcess)
            }
            FormRow(label: "亮度") { FieldComboBox(text: $preset.brightness, info: ParameterOptionCatalog.brightness) }
            FormRow(label: "对比度") { FieldComboBox(text: $preset.contrast, info: ParameterOptionCatalog.contrast) }
            FormRow(label: "饱和度") { FieldComboBox(text: $preset.saturation, info: ParameterOptionCatalog.saturation) }
            FormRow(label: "伽马") { FieldComboBox(text: $preset.gamma, info: ParameterOptionCatalog.gamma) }
        }
    }
}

struct CommonFiltersPane: View {
    @Binding var preset: PresetData

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            FormSection(title: "视频参数常见滤镜", note: "效果非常一般，仅建议临时场景使用。") {
                FormRow(label: "降噪方式", help: ParameterOptionCatalog.denoise.help) {
                    FieldComboBox(text: $preset.denoiseMode, info: ParameterOptionCatalog.denoise)
                }
                FormRow(label: "降噪参数1") { FieldComboBox(text: $preset.denoiseParameter1, info: ParameterOptionCatalog.denoiseParameter1) }
                FormRow(label: "降噪参数2") { FieldComboBox(text: $preset.denoiseParameter2, info: ParameterOptionCatalog.denoiseParameter2) }
                FormRow(label: "降噪参数3") { FieldComboBox(text: $preset.denoiseParameter3, info: ParameterOptionCatalog.denoiseParameter3) }
                FormRow(label: "降噪参数4") { FieldComboBox(text: $preset.denoiseParameter4, info: ParameterOptionCatalog.denoiseParameter4) }
                FormRow(label: "锐化水平尺寸") { FieldComboBox(text: $preset.sharpenWidth, info: ParameterOptionCatalog.sharpenWidth) }
                FormRow(label: "锐化垂直尺寸") { FieldComboBox(text: $preset.sharpenHeight, info: ParameterOptionCatalog.sharpenHeight) }
                FormRow(label: "锐化强度", help: ParameterOptionCatalog.sharpenStrength.help) {
                    FieldComboBox(text: $preset.sharpenStrength, info: ParameterOptionCatalog.sharpenStrength)
                }
            }
            FormSection(title: "烧录字幕", note: "用于把外部字幕或内嵌字幕烧录进画面。路径参数仍可手动输入。") {
                FormRow(label: "滤镜选择") {
                    FieldComboBox(text: $preset.subtitleBurnFilter, info: ParameterOptionCatalog.subtitleBurnFilter)
                }
                FormRow(label: "外部字幕") { Toggle("", isOn: $preset.subtitleExternalSource) }
                FormRow(label: "外部字幕文件名") { FieldComboBox(text: $preset.externalSubtitleFileName, info: ParameterFieldInfo(title: "外部字幕文件名", placeholder: "sub.ass / sub.srt")) }
                FormRow(label: "外部字幕文件夹") { FieldComboBox(text: $preset.externalSubtitleDirectory, info: ParameterFieldInfo(title: "外部字幕文件夹", placeholder: "留空使用输入文件目录")) }
                FormRow(label: "内嵌字幕流") { Toggle("", isOn: $preset.subtitleEmbeddedSource) }
                FormRow(label: "指定内嵌的流") { FieldComboBox(text: $preset.embeddedSubtitleStream, info: ParameterOptionCatalog.embeddedSubtitle) }
                FormRow(label: "字体文件夹") { FieldComboBox(text: $preset.subtitleFontsDirectory, info: ParameterFieldInfo(title: "字体文件夹", placeholder: "fontsdir")) }
                FormRow(label: "自定义样式") { FieldComboBox(text: $preset.subtitleCustomStyle, info: ParameterFieldInfo(title: "自定义样式", placeholder: "force_style 参数")) }
                FormRow(label: "自定义滤镜参数") { FieldComboBox(text: $preset.subtitleCustomFilterArguments, info: ParameterFieldInfo(title: "自定义滤镜参数", placeholder: "追加到 subtitles/ass 滤镜")) }
            }
        }
    }
}

struct FrameServerPane: View {
    @Binding var preset: PresetData

    var body: some View {
        FormSection(title: "视频帧服务器", note: "视频帧服务器又称视频脚本处理框架，用于对视频帧预处理并传递给编码器。这是高阶内容，如果你是新手，不要考虑这些。") {
            FormRow(label: "使用 AviSynth") { Toggle("", isOn: $preset.useAviSynth) }
            FormRow(label: "avs 脚本文件", help: ParameterOptionCatalog.avsScript.help) {
                FieldComboBox(text: $preset.aviSynthScript, info: ParameterOptionCatalog.avsScript)
            }
            FormRow(label: "使用 VapourSynth") { Toggle("", isOn: $preset.useVapourSynth) }
            FormRow(label: "vpy 脚本文件", help: ParameterOptionCatalog.vpyScript.help) {
                FieldComboBox(text: $preset.vapourSynthScript, info: ParameterOptionCatalog.vpyScript)
            }
        }
    }
}

struct AudioPane: View {
    @Binding var preset: PresetData

    var body: some View {
        FormSection(title: "音频参数", note: "音频编码、比特率、质量模式和响度标准化。为空则让 ffmpeg 使用默认行为。") {
            FormRow(label: "具体编码", help: ParameterOptionCatalog.audioEncoder.help) {
                FieldComboBox(text: $preset.audioEncoder, info: ParameterOptionCatalog.audioEncoder)
            }
            FormRow(label: "比特率", help: ParameterOptionCatalog.audioBitrate.help) {
                FieldComboBox(text: $preset.audioBitrate, info: ParameterOptionCatalog.audioBitrate)
            }
            FormRow(label: "质量参数名", help: ParameterOptionCatalog.audioQualityArgument.help) {
                FieldComboBox(text: $preset.audioQualityArgumentName, info: ParameterOptionCatalog.audioQualityArgument, normalize: normalizeOptionNameInput)
            }
            FormRow(label: "质量值") {
                FieldComboBox(text: $preset.audioQualityValue, info: ParameterOptionCatalog.audioQualityValue)
            }
            FormRow(label: "声道数") {
                FieldComboBox(text: $preset.audioChannels, info: ParameterOptionCatalog.audioChannels)
            }
            FormRow(label: "采样率") {
                FieldComboBox(text: $preset.audioSampleRate, info: ParameterOptionCatalog.audioSampleRate)
            }
            FormRow(label: "目标响度", help: ParameterOptionCatalog.loudnormTarget.help) {
                FieldComboBox(text: $preset.loudnormTarget, info: ParameterOptionCatalog.loudnormTarget)
            }
            FormRow(label: "动态范围", help: ParameterOptionCatalog.loudnormRange.help) {
                FieldComboBox(text: $preset.loudnormRange, info: ParameterOptionCatalog.loudnormRange)
            }
            FormRow(label: "峰值电平", help: ParameterOptionCatalog.loudnormPeak.help) {
                FieldComboBox(text: $preset.loudnormPeak, info: ParameterOptionCatalog.loudnormPeak)
            }
        }
    }
}

struct ImageParametersPane: View {
    @Binding var preset: PresetData

    var body: some View {
        FormSection(title: "图片参数", note: "图片参数也就是视频参数，只是为了分类而单独放这里。ffmpeg 不支持 heic / heif。") {
            FormRow(label: "编码名称", help: ParameterOptionCatalog.imageEncoder.help) {
                FieldComboBox(text: $preset.imageEncoder, info: ParameterOptionCatalog.imageEncoder)
            }
            FormRow(label: "质量值") {
                FieldComboBox(text: $preset.imageQuality, info: ParameterOptionCatalog.imageQuality)
            }
        }
    }
}

struct CustomArgumentsPane: View {
    @Binding var preset: PresetData

    var body: some View {
        FormSection(title: "自定义参数", note: "为各种细分领域和深度专业人士提供最大程度的自由。注意：所有换行都不会生效！") {
            FormRow(label: "视频滤镜") { FieldComboBox(text: $preset.customVideoFilter, info: ParameterOptionCatalog.customVideoFilter) }
            FormRow(label: "音频滤镜") { FieldComboBox(text: $preset.customAudioFilter, info: ParameterOptionCatalog.customAudioFilter) }
            FormRow(label: "filter_complex") { FieldComboBox(text: $preset.customFilterComplex, info: ParameterOptionCatalog.customFilterComplex) }
            FormRow(label: "视频参数") { FieldComboBox(text: $preset.customVideoArguments, info: ParameterOptionCatalog.customVideoArguments) }
            FormRow(label: "音频自定义参数") { FieldComboBox(text: $preset.customAudioArguments, info: ParameterOptionCatalog.customAudioArguments) }
            FormRow(label: "开头参数") { FieldComboBox(text: $preset.customLeadingArguments, info: ParameterOptionCatalog.customLeadingArguments) }
            FormRow(label: "之前参数") { FieldComboBox(text: $preset.customBeforeOutputArguments, info: ParameterOptionCatalog.customBeforeOutputArguments) }
            FormRow(label: "之后参数") { FieldComboBox(text: $preset.customAfterOutputArguments, info: ParameterOptionCatalog.customAfterOutputArguments) }
            FormRow(label: "最后参数") { FieldComboBox(text: $preset.customTrailingArguments, info: ParameterOptionCatalog.customTrailingArguments) }
            FormRow(label: "完全自己写", help: ParameterOptionCatalog.customFull.help) {
                TextEditor(text: $preset.customFullArguments)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 110)
            }
        }
    }
}

struct ClipPane: View {
    @Binding var preset: PresetData

    var body: some View {
        FormSection(title: "剪辑区间", note: "在提示板中查看注意事项。掐头去尾模式在旧版中也未找到稳定的一次性实现方案。") {
            FormRow(label: "方法") {
                MappedOptionComboBox(selection: $preset.clipMethod, placeholder: "方式", options: ParameterOptionCatalog.clipMethods)
            }
            FormRow(label: "入点", help: ParameterOptionCatalog.clipInPoint.help) {
                FieldComboBox(text: $preset.clipInPoint, info: ParameterOptionCatalog.clipInPoint)
            }
            FormRow(label: "出点") {
                FieldComboBox(text: $preset.clipOutPoint, info: ParameterOptionCatalog.clipOutPoint)
            }
            FormRow(label: "向前解码多久秒", help: ParameterOptionCatalog.clipPreDecode.help) {
                FieldComboBox(text: $preset.clipPreDecodeSeconds, info: ParameterOptionCatalog.clipPreDecode)
            }
        }
    }
}

struct StreamControlPane: View {
    @Binding var preset: PresetData

    var body: some View {
        FormSection(title: "流控制", note: "ffmpeg 的 -map 参数具有很高的优先级。使用指定流参数时，其他类型的流也可能需要带上 -map，否则 ffmpeg 可能会丢弃流；多轨媒体请谨慎。") {
            FormRow(label: "保留其他视频流") { Toggle("", isOn: $preset.keepOtherVideoStreams) }
            FormRow(label: "视频指定流", help: ParameterOptionCatalog.streamVideo.help) {
                FieldComboBox(text: stringArrayBinding($preset.videoStreamTargets), info: ParameterOptionCatalog.streamVideo)
            }
            FormRow(label: "保留其他音频流") { Toggle("", isOn: $preset.keepOtherAudioStreams) }
            FormRow(label: "音频指定流", help: ParameterOptionCatalog.streamAudio.help) {
                FieldComboBox(text: stringArrayBinding($preset.audioStreamTargets), info: ParameterOptionCatalog.streamAudio)
            }
            FormRow(label: "字幕指定流", help: ParameterOptionCatalog.streamSubtitle.help) {
                FieldComboBox(text: stringArrayBinding($preset.subtitleStreamTargets), info: ParameterOptionCatalog.streamSubtitle)
            }
            FormRow(label: "字幕操作", help: "mp4 仅支持 mov_text 字幕。") {
                MappedOptionComboBox(selection: $preset.subtitleOperation, placeholder: "如何操作", options: ParameterOptionCatalog.subtitleOperations)
            }
            FormRow(label: "保留其他字幕流") { Toggle("", isOn: $preset.keepOtherSubtitleStreams) }
            FormRow(label: "自动混流", help: "这些功能仅应用于首个 -i 的文件；会尝试混流同名字幕。") {
                HStack {
                    Toggle("SRT", isOn: $preset.autoMuxSRT)
                    Toggle("ASS", isOn: $preset.autoMuxASS)
                    Toggle("SSA", isOn: $preset.autoMuxSSA)
                    Toggle("转 MOVTEXT", isOn: $preset.autoMuxSubtitleToMovText)
                }
            }
            FormRow(label: "元数据选项", help: "这些功能强制使用 -map，注意和其他流控制参数的关系。") {
                MappedOptionComboBox(selection: $preset.metadataOption, placeholder: "元数据选项", options: ParameterOptionCatalog.metadataOptions)
            }
            FormRow(label: "章节选项") {
                MappedOptionComboBox(selection: $preset.chapterOption, placeholder: "章节选项", options: ParameterOptionCatalog.chapterOptions)
            }
            FormRow(label: "附件选项") {
                MappedOptionComboBox(selection: $preset.attachmentOption, placeholder: "附件选项", options: ParameterOptionCatalog.attachmentOptions)
            }
        }
    }
}

struct SchemeManagementPane: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var presetStore: PresetStore
    @EnvironmentObject private var settingsStore: SettingsStore
    @Binding var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(t("方案管理"))
                .font(.title2.weight(.semibold))
            Text(t("不保证跨版本通用，使用非当前版本则某些设置可能未还原，版本相差过大或早期版本会直接报错。\n选中项进行操作；双击快速读取；重复选中进入编辑模式来重命名。\n选中时进行保存是覆盖到选中，不选中时会新建，删除直接手动删文件即可，位于根目录下的 Preset 文件夹。"))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
            HStack {
                Button(t("新建方案")) { presetStore.reset() }
                Button(t("导入 .3fui / JSON")) { appState.presentPresetImportPanel() }
                Button(t("导出 .3fui")) { appState.presentPresetExportPanel() }
            }
            .buttonStyle(.bordered)
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 10) {
                FormRow(label: "自动加载预设", help: "自动加载功能说明：受限于选项卡控件的机制，旧版启动后必须切到参数面板才会自动加载；SwiftUI 版本保存设置但不强制恢复旧版切页机制。") {
                    MappedOptionComboBox(selection: $settings.presetAutoLoadMode, placeholder: "自动加载预设", options: ParameterOptionCatalog.presetAutoLoadModes)
                }
                FormRow(label: "指定预设路径") {
                    FieldComboBox(text: $settings.presetAutoLoadPath, info: ParameterOptionCatalog.presetAutoLoadPath)
                }
            }
            Text(presetStore.lastMessage)
                .foregroundStyle(.secondary)
        }
    }

    private func t(_ key: String) -> String {
        L10n.text(key, language: settingsStore.settings.language)
    }
}

func stringArrayBinding(_ binding: Binding<[String]>) -> Binding<String> {
    Binding<String>(
        get: { binding.wrappedValue.joined(separator: ",") },
        set: {
            binding.wrappedValue = $0.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
    )
}
