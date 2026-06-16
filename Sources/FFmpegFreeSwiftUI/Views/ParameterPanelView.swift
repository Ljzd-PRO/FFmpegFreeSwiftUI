import AppKit
import SwiftUI

private enum ParameterTab: String, CaseIterable, Identifiable {
    case overview = "参数总览"
    case output = "输出文件设置"
    case decoding = "解码设置"
    case videoEncoder = "视频参数编码器"
    case videoFrame = "视频参数画面帧"
    case videoQuality = "视频参数质量"
    case color = "视频参数色彩管理"
    case commonFilters = "视频参数常见滤镜"
    case frameServer = "视频帧服务器"
    case audio = "音频参数"
    case image = "图片参数"
    case custom = "自定义参数"
    case clip = "剪辑区间"
    case stream = "流控制"
    case scheme = "方案管理"

    var id: String { rawValue }
}

public struct ParameterPanelView: View {
    @EnvironmentObject private var presetStore: PresetStore
    @EnvironmentObject private var settingsStore: SettingsStore
    @StateObject private var capabilityStore = VideoEncoderCapabilityStore()
    @State private var selection: ParameterTab = .overview

    public init() {}

    public var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(ParameterTab.allCases) { tab in
                        Button {
                            selection = tab
                        } label: {
                            Text(tab.rawValue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(selection == tab ? .primary : .secondary)
                        .background(selection == tab ? Color.accentColor.opacity(0.18) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(8)
            }
            .frame(width: 220)
            Divider()
            ScrollView {
                Group {
                    switch selection {
                    case .overview:
                        OverviewPane(preset: $presetStore.current)
                    case .output:
                        OutputSettingsPane(preset: $presetStore.current)
                    case .decoding:
                        DecodingPane(preset: $presetStore.current)
                    case .videoEncoder:
                        VideoEncoderPane(preset: $presetStore.current, probedCapabilities: capabilityStore.capabilities)
                    case .videoFrame:
                        VideoFramePane(preset: $presetStore.current)
                    case .videoQuality:
                        VideoQualityPane(preset: $presetStore.current, probedCapabilities: capabilityStore.capabilities)
                    case .color:
                        ColorPane(preset: $presetStore.current, probedCapabilities: capabilityStore.capabilities)
                    case .commonFilters:
                        CommonFiltersPane(preset: $presetStore.current)
                    case .frameServer:
                        FrameServerPane(preset: $presetStore.current)
                    case .audio:
                        AudioPane(preset: $presetStore.current)
                    case .image:
                        ImageParametersPane(preset: $presetStore.current)
                    case .custom:
                        CustomArgumentsPane(preset: $presetStore.current)
                    case .clip:
                        ClipPane(preset: $presetStore.current)
                    case .stream:
                        StreamControlPane(preset: $presetStore.current)
                    case .scheme:
                        SchemeManagementPane(settings: $settingsStore.settings)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .task {
            capabilityStore.refresh(settings: settingsStore.settings)
        }
        .onChange(of: settingsStore.settings.ffmpegExecutableOverride) { _ in
            capabilityStore.refresh(settings: settingsStore.settings)
        }
        .onChange(of: presetStore.current) { _ in
            presetStore.persistAsLastPreset()
        }
    }
}

@MainActor
private final class VideoEncoderCapabilityStore: ObservableObject {
    @Published var capabilities: [String: VideoEncoderCapability] = [:]
    private var lastFFmpegPath = ""

    func refresh(settings: AppSettings) {
        let ffmpegPath = FFmpegLocator(settings: settings).locate(.ffmpeg)
        guard ffmpegPath != lastFFmpegPath else { return }
        lastFFmpegPath = ffmpegPath

        Task {
            let probed = await VideoEncoderCapabilityCatalog.probeVideoToolboxEncoders(ffmpegPath: ffmpegPath)
            capabilities = probed
        }
    }
}

private struct FormSection<Content: View>: View {
    var title: String
    var note: String = ""
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            if !note.isEmpty {
                Text(note)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 10) {
                content
            }
        }
        .padding(.bottom, 18)
    }
}

private struct FormRow<Content: View>: View {
    var label: String
    var help: String = ""
    @ViewBuilder var content: Content

    var body: some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 170, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                content
                    .frame(maxWidth: 560, alignment: .leading)
                if !help.isEmpty {
                    Text(help)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: 620, alignment: .leading)
        }
    }
}

private struct ParameterFieldInfo {
    var title: String
    var placeholder: String = ""
    var help: String = ""
    var options: [ParameterOption] = []
}

private struct ParameterOption: Hashable {
    var title: String
    var value: String

    init(_ value: String) {
        title = value
        self.value = value
    }

    init(title: String, value: String) {
        self.title = title
        self.value = value
    }
}

private struct MappedOption<Value: Hashable>: Hashable {
    var title: String
    var value: Value
}

private struct EditableComboBox: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var options: [ParameterOption]

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, options: options)
    }

    func makeNSView(context: Context) -> NSComboBox {
        let comboBox = NSComboBox()
        comboBox.usesDataSource = false
        comboBox.completes = true
        comboBox.isEditable = true
        comboBox.numberOfVisibleItems = 12
        comboBox.delegate = context.coordinator
        comboBox.translatesAutoresizingMaskIntoConstraints = false
        comboBox.setContentHuggingPriority(.defaultLow, for: .horizontal)
        comboBox.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return comboBox
    }

    func updateNSView(_ comboBox: NSComboBox, context: Context) {
        context.coordinator.text = $text
        context.coordinator.options = options
        comboBox.placeholderString = placeholder
        let displayText = options.first(where: { $0.value == text && !$0.title.isEmpty })?.title ?? text
        if comboBox.stringValue != displayText {
            comboBox.stringValue = displayText
        }
        let titles = options.map(\.title)
        if comboBox.numberOfItems != titles.count || (0..<comboBox.numberOfItems).map({ comboBox.itemObjectValue(at: $0) as? String ?? "" }) != titles {
            comboBox.removeAllItems()
            comboBox.addItems(withObjectValues: titles)
        }
    }

    final class Coordinator: NSObject, NSComboBoxDelegate {
        var text: Binding<String>
        var options: [ParameterOption]

        init(text: Binding<String>, options: [ParameterOption]) {
            self.text = text
            self.options = options
        }

        func comboBoxSelectionDidChange(_ notification: Notification) {
            guard let comboBox = notification.object as? NSComboBox else { return }
            let index = comboBox.indexOfSelectedItem
            if options.indices.contains(index) {
                text.wrappedValue = options[index].value
                comboBox.stringValue = options[index].title
            }
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let comboBox = notification.object as? NSComboBox else { return }
            let visibleText = comboBox.stringValue
            if let option = options.first(where: { $0.title == visibleText }) {
                text.wrappedValue = option.value
            } else {
                text.wrappedValue = visibleText
            }
        }
    }
}

private struct FieldComboBox: View {
    @Binding var text: String
    var info: ParameterFieldInfo
    var options: [ParameterOption]? = nil
    var normalize: (String) -> String = { $0 }

    private var normalizedText: Binding<String> {
        Binding<String>(
            get: { text },
            set: { text = normalize($0) }
        )
    }

    var body: some View {
        EditableComboBox(text: normalizedText, placeholder: info.placeholder, options: options ?? info.options)
            .frame(height: 24)
    }
}

private struct MappedOptionComboBox<Value: Hashable>: View {
    @Binding var selection: Value
    var placeholder: String
    var options: [MappedOption<Value>]

    private var textBinding: Binding<String> {
        Binding<String>(
            get: {
                options.first(where: { $0.value == selection })?.title ?? ""
            },
            set: { newValue in
                if let option = options.first(where: { $0.title == newValue }) {
                    selection = option.value
                }
            }
        )
    }

    var body: some View {
        EditableComboBox(
            text: textBinding,
            placeholder: placeholder,
            options: options.map { ParameterOption(title: $0.title, value: $0.title) }
        )
        .frame(height: 24)
    }
}

private struct VideoEncoderProfile {
    var presets: [ParameterOption]
    var profiles: [ParameterOption]
    var tunes: [ParameterOption]
    var pixelFormats: [ParameterOption]
}

private enum ParameterOptionCatalog {
    static let outputContainer = ParameterFieldInfo(
        title: "输出容器",
        placeholder: "填写输出容器（后缀）",
        help: "输出文件扩展名，可写 mp4、mkv、mov；开头的点会自动去掉。",
        options: opts(["mp4", "mkv", "mov", "webm", "flv", "avi", "mp3", "m4a", "flac", "wav", "png", "jpg", "webp", "gif"])
    )
    static let outputLocation = ParameterFieldInfo(
        title: "输出位置",
        placeholder: "选择输出目录",
        help: "输出目录默认不会保存到预设方案中；留空输出到原目录。也可以直接粘贴目录路径。",
        options: [ParameterOption(title: "输出到原目录", value: "")]
    )
    static let outputPrefix = ParameterFieldInfo(title: "开头文本", placeholder: "输出文件以什么开头")
    static let outputReplacement = ParameterFieldInfo(title: "替代文本", placeholder: "不使用输入文件的名称，而是使用这里的")
    static let outputSuffix = ParameterFieldInfo(title: "结尾文本", placeholder: "输出文件以什么结尾")

    static let decoder = ParameterFieldInfo(
        title: "解码器",
        placeholder: "-hwaccel",
        help: "如果你不知道要设置成什么，就不要设置。cuda = NVIDIA，qsv = Intel，amf = AMD；macOS 可尝试 videotoolbox。",
        options: opts(["", "auto", "cpu", "videotoolbox", "cuda", "qsv", "amf", "vaapi", "vulkan", "opencl", "d3d11va", "d3d12va", "dxva2"])
    )
    static let decoderThreads = ParameterFieldInfo(
        title: "CPU 解码线程数",
        placeholder: "-threads",
        help: "如果正在使用 CPU 解码，可以指定解码线程数，通常不需要指定。",
        options: opts(["", "1", "2", "4", "6", "8", "12", "16"])
    )
    static let decoderOutputFormat = ParameterFieldInfo(
        title: "解码数据格式",
        placeholder: "-hwaccel_output_format",
        help: "如果解码和编码不是相同的硬件加速，才可能需要设置。出问题再考虑。",
        options: opts(["", "videotoolbox", "d3d11", "cuda", "qsv", "vaapi", "vulkan", "yuv420p", "nv12", "p010"])
    )
    static let decoderHardwareArgumentName = ParameterFieldInfo(
        title: "指定硬件参数名",
        placeholder: "选择参数",
        help: "用于指定硬件加速解码设备，多张同品牌显卡时可能有用。",
        options: opts(["", "-hwaccel_device", "-init_hw_device", "-qsv_device"])
    )
    static let decoderHardwareArgument = ParameterFieldInfo(
        title: "指定硬件参数",
        placeholder: "？",
        help: "如果安装了多张同品牌显卡，可以指定使用哪张卡，可能无效。"
    )

    static let videoEncoderCategory = ParameterFieldInfo(
        title: "类别",
        placeholder: "选择类别",
        help: "先选类别，再选具体编码；这里是为了归类选择，具体编码才是真正传给 ffmpeg 的名称。",
        options: opts(["", "复制流", "H.266/VVC", "AV1", "H.265/HEVC", "H.264/AVC", "来自 Apple", "来自 Google", "FFV1", "其他现代编码", "老旧编码", "禁用", "自定义的项"])
    )
    static let videoEncoder = ParameterFieldInfo(
        title: "具体编码",
        placeholder: "具体编码 -c:v",
        help: "lib = CPU，nvenc = NVIDIA，qsv = Intel，amf = AMD；macOS 常见硬件编码为 videotoolbox。"
    )
    static let videoPreset = ParameterFieldInfo(
        title: "编码预设",
        placeholder: "-preset",
        help: "编码预设用于平衡压缩度和编码速度；通常越慢压缩越好。"
    )
    static let videoProfile = ParameterFieldInfo(
        title: "配置文件",
        placeholder: "-profile",
        help: "配置文件决定兼容的技术规格和功能，一般不用指定。"
    )
    static let videoTune = ParameterFieldInfo(
        title: "场景优化",
        placeholder: "-tune",
        help: "对特定需求的专项优化，大多数情况不用指定。"
    )
    static let videoGPU = ParameterFieldInfo(
        title: "GPU",
        placeholder: "-gpu",
        help: "多张同品牌显卡时指定卡；不同编码器支持情况不一致。",
        options: opts(["", "0", "1", "2", "3"])
    )
    static let videoThreads = ParameterFieldInfo(
        title: "threads",
        placeholder: "-threads",
        help: "指定 CPU 编码线程数，一般不需要考虑。",
        options: opts(["", "1", "2", "4", "6", "8", "12", "16"])
    )

    static let resolution = ParameterFieldInfo(
        title: "分辨率",
        placeholder: "-s",
        help: "指定宽度和高度，建议优先考虑自动计算；这个是在滤镜里处理的。",
        options: opts(["1280x720", "1600x900", "1920x1080", "2560x1440", "3840x2160", "7680x4320"])
    )
    static let autoWidth = ParameterFieldInfo(title: "自动宽度", placeholder: "宽度", help: "给定宽度或高度之一即可自动计算另一个。")
    static let autoHeight = ParameterFieldInfo(title: "自动高度", placeholder: "高度", help: "给定宽度或高度之一即可自动计算另一个。")
    static let crop = ParameterFieldInfo(title: "裁剪滤镜参数", placeholder: "-crop", help: "画面裁剪可以与自动计算的分辨率一起使用，会先裁剪再缩放。")
    static let frameRate = ParameterFieldInfo(
        title: "帧速率",
        placeholder: "-r",
        help: "指定帧率为固定帧率；如果还要用外挂字幕观看则不要抽帧。",
        options: opts(["23.976", "24", "25", "29.97", "30", "50", "59.94", "60", "120"])
    )
    static let decimateRatio = ParameterFieldInfo(title: "抽帧最大变化比例", placeholder: "0.？", help: "0~1，0.01 = 1%，最低 0.01；变化低于此则抽帧。")
    static let targetFPS = ParameterFieldInfo(title: "目标帧率", placeholder: "24 / 30 / 60", options: frameRate.options)

    static let bitrateControl = ParameterFieldInfo(
        title: "控制方式",
        placeholder: "控制方式 -rc",
        help: "软件编码首选 CRF，N 卡首选 CQ，I 卡首选 global_quality；也可直接设置质量参数和值。",
        options: [
            ParameterOption(title: "", value: ""),
            ParameterOption(title: "恒定质量 CRF - 软件编码首选", value: "CRF"),
            ParameterOption(title: "动态码率 VBR - 硬件加速首选", value: "VBR"),
            ParameterOption(title: "动态码率 VBR HQ - 硬件加速专用", value: "VBR HQ"),
            ParameterOption(title: "恒定量化 CQP - 研究和特定场景", value: "CQP"),
            ParameterOption(title: "恒定速率 CBR - 较少使用", value: "CBR")
        ]
    )
    static let qualityArgument = ParameterFieldInfo(
        title: "质量参数名",
        placeholder: "质量参数",
        options: opts(["", "-crf", "-cq", "-qp", "-global_quality"])
    )
    static let qualityValue = ParameterFieldInfo(title: "质量值", placeholder: "质量值")
    static let bitrateBase = ParameterFieldInfo(title: "比特率基础", placeholder: "-b:v", help: "传统转码直接指定数据速率；记得带单位，例如 5000k、5m。")
    static let bitrateMin = ParameterFieldInfo(title: "最低值", placeholder: "-minrate")
    static let bitrateMax = ParameterFieldInfo(title: "最高值", placeholder: "-maxrate")
    static let bitrateBuffer = ParameterFieldInfo(title: "缓冲区", placeholder: "-bufsize")
    static let advancedQuality = ParameterFieldInfo(title: "进阶参数集", placeholder: "-x265-params key=value 或多个参数", help: "添加预制或空项然后编辑参数；编码器内部小参可在自定义参数里写。")

    static let pixelFormat = ParameterFieldInfo(
        title: "像素格式",
        placeholder: "-pix_fmt",
        help: "指定像素如何存储；下拉选项跟随选择的编码器，也可以自己写。",
        options: opts(commonPixelFormats)
    )
    static let colorFilter = ParameterFieldInfo(
        title: "滤镜选择",
        placeholder: "选择滤镜",
        help: "zscale (CPU)；libplacebo (GPU)，转换杜比视界推荐 libplacebo。",
        options: opts(["", "zscale", "libplacebo"])
    )
    static let colorMatrix = ParameterFieldInfo(title: "矩阵系数", placeholder: "colorspace", help: "矩阵系数 / 颜色格式决定亮度和色度的分配方式。", options: opts(["", "auto", "bt709", "bt2020nc", "bt2020c", "rgb", "gbr", "bt470bg", "smpte170m", "smpte240m", "fcc", "ictcp", "ycgco", "xyz"]))
    static let colorPrimaries = ParameterFieldInfo(title: "色域", placeholder: "color_primaries", help: "色域指定采用哪一套色彩标准。", options: opts(["", "auto", "bt709", "bt2020", "smpte428", "smpte431", "smpte432", "film", "bt470m", "bt470bg", "smpte170m", "smpte240m", "jedec-p22", "ebu3213"]))
    static let colorTransfer = ParameterFieldInfo(title: "传输特性", placeholder: "color_trc", help: "传输特性描述数值与实际光亮度之间的非线性关系。", options: opts(["", "auto", "bt709", "bt2020-10", "bt2020-12", "smpte2084", "bt470m", "bt470bg", "log", "log_sqrt", "linear", "bt1361e", "iec61966-2-1", "iec61966-2-4", "smpte170m", "smpte240m", "gamma22", "gamma28", "arib-std-b67"]))
    static let colorRange = ParameterFieldInfo(title: "范围", placeholder: "color_range", help: "实际上大多数视频是有限范围而不是完全范围。", options: [ParameterOption(title: "", value: ""), ParameterOption(title: "tv 有限 16~235", value: "tv"), ParameterOption(title: "pc 全范围 0~255", value: "pc")])
    static let tonemap = ParameterFieldInfo(title: "色调映射算法", placeholder: "tonemapping", help: "[可选] 色调映射算法，仅限 libplacebo。", options: opts(["", "auto", "clip", "st2094-40", "st2094-10", "bt.2390", "bt.2446a", "spline", "reinhard", "mobius", "hable", "gamma", "linear"]))
    static let colorProcess = ParameterFieldInfo(title: "处理方式", placeholder: "处理方式", help: "必须设置处理方式才会使用滤镜；标准转换通常选择写入元数据并转换。", options: [ParameterOption(title: "", value: ""), ParameterOption(title: "写入元数据并转换", value: "写入元数据并转换"), ParameterOption(title: "仅写入元数据", value: "仅写入元数据"), ParameterOption(title: "仅转换", value: "仅转换")])
    static let brightness = ParameterFieldInfo(title: "亮度", placeholder: "-1.0~1.0，原 0")
    static let contrast = ParameterFieldInfo(title: "对比度", placeholder: "0.0~2.0，原 1")
    static let saturation = ParameterFieldInfo(title: "饱和度", placeholder: "0.0~3.0，原 1")
    static let gamma = ParameterFieldInfo(title: "伽马", placeholder: "0.1~10.0，原 1")

    static let denoise = ParameterFieldInfo(
        title: "降噪方式",
        placeholder: "选择降噪方式",
        help: "去除画面中的噪点；水印文字不是默认填写的值。",
        options: [
            ParameterOption(title: "", value: ""),
            ParameterOption(title: "hqdn3d - 时空域降噪，适合普通噪声", value: "hqdn3d"),
            ParameterOption(title: "nlmeans - 高级降噪，效果更好速度更慢", value: "nlmeans"),
            ParameterOption(title: "atadenoise - 轻量级时间域降噪", value: "atadenoise"),
            ParameterOption(title: "bm3d - 高质量降噪，适合严重噪声", value: "bm3d")
        ]
    )
    static let subtitleBurnFilter = ParameterFieldInfo(title: "滤镜选择", placeholder: "选择字幕滤镜", options: opts(["subtitles", "ass"]))
    static let embeddedSubtitle = ParameterFieldInfo(title: "指定内嵌的流", placeholder: "0:s:0")
    static let denoiseParameter1 = ParameterFieldInfo(title: "降噪参数1", placeholder: "参数1")
    static let denoiseParameter2 = ParameterFieldInfo(title: "降噪参数2", placeholder: "参数2")
    static let denoiseParameter3 = ParameterFieldInfo(title: "降噪参数3", placeholder: "参数3")
    static let denoiseParameter4 = ParameterFieldInfo(title: "降噪参数4", placeholder: "参数4")
    static let sharpenWidth = ParameterFieldInfo(title: "锐化水平尺寸", placeholder: "尺寸 3")
    static let sharpenHeight = ParameterFieldInfo(title: "锐化垂直尺寸", placeholder: "尺寸 3")
    static let sharpenStrength = ParameterFieldInfo(title: "锐化强度", placeholder: "强度 1", help: "强调物体边缘，适当增加清晰度；建议的值：尺寸 3，强度 1。")

    static let avsScript = ParameterFieldInfo(title: "avs 脚本文件", placeholder: "选择 .avs 文件", help: "在 .avs 脚本文件中使用 <FilePath> 表示输入文件路径；AviSynth 在 macOS 需要自行配置兼容环境。", options: [ParameterOption(title: "浏览 ...", value: "")])
    static let vpyScript = ParameterFieldInfo(title: "vpy 脚本文件", placeholder: "选择 .vpy/.py 文件", help: "在 .vpy/.py 脚本文件中使用 <FilePath> 表示输入文件路径。", options: [ParameterOption(title: "浏览 ...", value: "")])

    static let audioEncoder = ParameterFieldInfo(
        title: "具体编码",
        placeholder: "选择音频编码",
        help: "注意 FFmpeg 主流发行版未必包含所选编码器。",
        options: [
            ParameterOption(title: "", value: ""),
            ParameterOption(title: "复制流", value: "copy"),
            ParameterOption(title: "禁用", value: "禁用"),
            ParameterOption(title: "AAC", value: "aac"),
            ParameterOption(title: "FDK AAC", value: "libfdk_aac"),
            ParameterOption(title: "FDK AAC HE", value: "libfdk_aac"),
            ParameterOption(title: "FDK AAC HE v2", value: "libfdk_aac"),
            ParameterOption(title: "LAME MP3", value: "libmp3lame"),
            ParameterOption(title: "Opus", value: "libopus"),
            ParameterOption(title: "FLAC", value: "flac"),
            ParameterOption(title: "ALAC", value: "alac"),
            ParameterOption(title: "WAV 16bit", value: "pcm_s16le"),
            ParameterOption(title: "WAV 24bit", value: "pcm_s24le"),
            ParameterOption(title: "WAV 32bit", value: "pcm_s32le"),
            ParameterOption(title: "WAV 64bit", value: "pcm_s64le"),
            ParameterOption(title: "ATSC A/52A (AC3)", value: "ac3"),
            ParameterOption(title: "ATSC A/52B (EAC3)", value: "eac3"),
            ParameterOption(title: "DTS Coherent Acoustics", value: "dca"),
            ParameterOption(title: "TrueHD", value: "truehd"),
            ParameterOption(title: "True Audio", value: "tta"),
            ParameterOption(title: "Vorbis (ogg)", value: "libvorbis"),
            ParameterOption(title: "RealAudio 1.0 (14.4K)", value: "real_144"),
            ParameterOption(title: "WavPack", value: "wavpack"),
            ParameterOption(title: "LAME MP2", value: "mp2"),
            ParameterOption(title: "AMR-NB", value: "libopencore_amrnb"),
            ParameterOption(title: "AMR-WB", value: "libvo_amrwbenc")
        ]
    )
    static let audioBitrate = ParameterFieldInfo(title: "比特率", placeholder: "选择或输入比特率", help: "恒定码率 CBR，填写比特率即可。", options: opts(["", "96k", "128k", "192k", "256k", "320k", "384k", "448k", "512k", "640k", "1411k"]))
    static let audioQualityArgument = ParameterFieldInfo(title: "质量参数名", placeholder: "选择质量参数", help: "质量模式，不写比特率；注意查询每种编码器的质量取值范围。", options: opts(["", "-q:a", "-vbr", "-compression_level"]))
    static let audioQualityValue = ParameterFieldInfo(title: "质量值", placeholder: "质量值")
    static let audioChannels = ParameterFieldInfo(title: "声道数", placeholder: "选择声道布局", options: opts(["", "mono", "stereo", "2.1", "4.0", "5.0", "5.1", "6.1", "7.1", "hexagonal", "octagonal"]))
    static let audioSampleRate = ParameterFieldInfo(title: "采样率", placeholder: "选择采样率", options: opts(["", "192000", "96000", "48000", "44100", "32000", "24000", "22050", "16000", "11025", "8000"]))
    static let loudnormTarget = ParameterFieldInfo(title: "目标响度", placeholder: "LUFS", help: "我国广电标准 -24，国际标准 -23；数字越大声音越响，不建议大于 -16。")
    static let loudnormRange = ParameterFieldInfo(title: "动态范围", placeholder: "LU", help: "不建议超过 20，一般取 1~10。")
    static let loudnormPeak = ParameterFieldInfo(title: "峰值电平", placeholder: "dBTP", help: "我国广电标准 -2，国际标准 -1，不应大于此值。")

    static let imageEncoder = ParameterFieldInfo(
        title: "编码名称",
        placeholder: "选择编码名称",
        help: "图片参数也就是视频参数，只是为了分类而单独放这里。",
        options: [
            ParameterOption(title: "", value: ""),
            ParameterOption(title: "PNG | 1 最快 ~ 最慢 9", value: "png"),
            ParameterOption(title: "APNG 动图 | 1 最快 ~ 最慢 9", value: "apng"),
            ParameterOption(title: "JPEG\\JPG | 1 清晰 ~ 模糊 31", value: "mjpeg"),
            ParameterOption(title: "WEBP | 0 模糊 ~ 清晰 100", value: "libwebp"),
            ParameterOption(title: "WEBP 动图", value: "libwebp_anim"),
            ParameterOption(title: "GIF 动图 | 写 1 来启用调色板生成", value: "gif"),
            ParameterOption(title: "BMP", value: "bmp"),
            ParameterOption(title: "OpenJPEG | 0.0 全损 ~ 无损 1.0", value: "libopenjpeg"),
            ParameterOption(title: "JPEG-LS", value: "jpegls"),
            ParameterOption(title: "SVT JPEG XS", value: "libsvt_jpegxs"),
            ParameterOption(title: "HDR (Radiance RGBE format)", value: "hdr"),
            ParameterOption(title: "TIFF", value: "tiff"),
            ParameterOption(title: "DPX", value: "dpx"),
            ParameterOption(title: "OpenEXR", value: "exr")
        ]
    )
    static let imageQuality = ParameterFieldInfo(title: "质量值", placeholder: "质量值")

    static let customVideoFilter = ParameterFieldInfo(title: "视频滤镜", placeholder: "这里的参数将作为 -vf 的参数拼接在已生成部分的末尾，每个滤镜用英文逗号隔开，图片的也是用这个")
    static let customAudioFilter = ParameterFieldInfo(title: "音频滤镜", placeholder: "这里的参数将作为 -af 的参数拼接在已生成部分的末尾，每个滤镜用英文逗号隔开")
    static let customFilterComplex = ParameterFieldInfo(title: "filter_complex", placeholder: "这里的参数将作为 -filter_complex 滤镜参数，每个滤镜用英文逗号隔开，3FUI 自身没有使用此参数")
    static let customVideoArguments = ParameterFieldInfo(title: "视频参数", placeholder: "这里的参数将拼接在所有视频参数的末尾（音频参数之前）图片参数也是这个")
    static let customAudioArguments = ParameterFieldInfo(title: "音频参数", placeholder: "这里的参数将拼接在所有音频参数的末尾")
    static let customLeadingArguments = ParameterFieldInfo(title: "开头参数", placeholder: "这里的参数将拼接在输入文件之前（ffmpeg 之后，-i 之前）")
    static let customBeforeOutputArguments = ParameterFieldInfo(title: "之前参数", placeholder: "这里的参数将拼接在主输入文件之后（用于导入更多文件）")
    static let customAfterOutputArguments = ParameterFieldInfo(title: "之后参数", placeholder: "这里的参数将拼接在前面所有参数的后面，但在输出文件之前")
    static let customTrailingArguments = ParameterFieldInfo(title: "最后参数", placeholder: "这里的参数将拼接在所有参数之后（在输出文件之后，也就是最末尾的位置）")
    static let customFull = ParameterFieldInfo(title: "完全自己写", help: "完全自己写时，其他所有参数全都不会生效。不要包含开头的 ffmpeg；用 <InputFile> 表示输入文件，用 <OutputFile> 表示输出文件，不会自动写引号，区分大小写。")

    static let clipInPoint = ParameterFieldInfo(title: "入点", placeholder: "入点 -ss", help: "时间格式：时:分:秒.毫秒；可以只写一个来表示从指定时间到末尾或从开头到指定时间。")
    static let clipOutPoint = ParameterFieldInfo(title: "出点", placeholder: "出点 -to")
    static let clipPreDecode = ParameterFieldInfo(title: "向前解码多久秒", placeholder: "向前解码多久", help: "仅限精剪 (快速响应) 使用；只能写数字，单位是秒。", options: opts(["", "10", "20", "30", "60", "120", "240", "360", "600"]))

    static let streamVideo = ParameterFieldInfo(title: "视频指定流", placeholder: "多个用逗号隔开", help: "文件索引:v:流索引；0:v 表示第一个文件的全部视频流。")
    static let streamAudio = ParameterFieldInfo(title: "音频指定流", placeholder: "多个用逗号隔开", help: "文件索引:a:流索引；0:a 表示第一个文件的全部音频流。")
    static let streamSubtitle = ParameterFieldInfo(title: "字幕指定流", placeholder: "多个用逗号隔开", help: "文件索引:s:流索引；0:s 表示第一个文件的全部字幕流。")

    static let presetAutoLoadPath = ParameterFieldInfo(title: "自动加载的预设文件路径", placeholder: "加载指定的预设文件")

    static let autoNamingOptions: [MappedOption<PresetData.AutoNamingOption>] = [
        .init(title: "附加 _时间戳（默认）", value: .timestamp),
        .init(title: "附加 ~1", value: .incrementNumber),
        .init(title: "附加 _3fui", value: .append3FUI),
        .init(title: "常规压片 (编码器+质量)", value: .encoderAndQuality),
        .init(title: "附加 _8位随机数字", value: .random8Digits),
        .init(title: "附加 _16位随机数字", value: .random16Digits),
        .init(title: "附加 _8位随机字母", value: .random8Letters),
        .init(title: "附加 _16位随机字母", value: .random16Letters),
        .init(title: "附加 _8位随机数字和字母", value: .random8Alphanumeric),
        .init(title: "附加 _16位随机数字和字母", value: .random16Alphanumeric)
    ]

    static let clipMethods: [MappedOption<PresetData.ClipMethod>] = [
        .init(title: "", value: .unknown),
        .init(title: "粗剪 (立即响应)", value: .rough),
        .init(title: "精剪 (从头解码)", value: .preciseFromStart),
        .init(title: "精剪 (快速响应)", value: .preciseWithPreseek),
        .init(title: "Trim 滤镜", value: .trimFilter),
        .init(title: "掐头去尾", value: .trimHeadTail)
    ]

    static let deinterlaceModes: [MappedOption<Int>] = [
        .init(title: "", value: 0),
        .init(title: "隔行转逐行 - yadif 单帧输入+自动场序+空间检查", value: 1),
        .init(title: "隔行转逐行 - yadif 单帧输入+顶场优先+空间检查", value: 2),
        .init(title: "隔行转逐行 - yadif 单帧输入+底场优先+空间检查", value: 3),
        .init(title: "逐行转隔行 - tinterlace 顶场优先", value: 4),
        .init(title: "逐行转隔行 - tinterlace 底场优先", value: 5),
        .init(title: "NTSC 标准 IVTC 胶片 3:2 pulldown 转逐行", value: 6),
        .init(title: "NTSC 纯隔行 非胶片 转逐行", value: 7),
        .init(title: "NTSC 自动检测 pulldown 模式至 25fps", value: 8),
        .init(title: "PAL 标准反交错", value: 9),
        .init(title: "PAL 标准反交错 双倍帧率", value: 10),
        .init(title: "PAL 高质量反交错", value: 11),
        .init(title: "PAL 高质量反交错 双倍帧率", value: 12)
    ]
    static let rotateModes: [MappedOption<Int>] = [
        .init(title: "", value: 0),
        .init(title: "顺时针旋转 90°", value: 1),
        .init(title: "顺时针旋转 180°", value: 3),
        .init(title: "顺时针旋转 270°", value: 2),
        .init(title: "逆时针旋转 90°", value: 2),
        .init(title: "逆时针旋转 180°", value: 3),
        .init(title: "逆时针旋转 270°", value: 1)
    ]
    static let mirrorModes: [MappedOption<Int>] = [
        .init(title: "", value: 0),
        .init(title: "水平镜像", value: 1),
        .init(title: "垂直镜像", value: 2)
    ]
    static let subtitleOperations: [MappedOption<Int>] = [
        .init(title: "", value: 0),
        .init(title: "复制流", value: 1),
        .init(title: "转为 mov_text", value: 2),
        .init(title: "转为 srt", value: 3),
        .init(title: "转为 ass", value: 4),
        .init(title: "转为 ssa", value: 5)
    ]
    static let metadataOptions: [MappedOption<Int>] = [
        .init(title: "", value: 0),
        .init(title: "保留元数据", value: 1),
        .init(title: "清除元数据", value: 2),
        .init(title: "保留更多元数据", value: 3)
    ]
    static let chapterOptions: [MappedOption<Int>] = [
        .init(title: "", value: 0),
        .init(title: "保留章节", value: 1),
        .init(title: "清除章节", value: 2)
    ]
    static let attachmentOptions: [MappedOption<Int>] = [
        .init(title: "", value: 0),
        .init(title: "保留附件", value: 1)
    ]
    static let presetAutoLoadModes: [MappedOption<Int>] = [
        .init(title: "不自动加载预设", value: 0),
        .init(title: "自动加载最后的预设文件", value: 1),
        .init(title: "自动加载指定的预设文件", value: 2),
        .init(title: "自动加载上次的全部改动", value: 3)
    ]

    static func videoEncoders(for category: String) -> [ParameterOption] {
        switch category {
        case "复制流":
            return opts(["copy"])
        case "H.266/VVC":
            return opts(["libvvenc", "libx266"])
        case "AV1":
            return opts(["libsvtav1", "av1_nvenc", "av1_qsv", "av1_amf", "av1_d3d12va", "libaom-av1", "librav1e", "av1_vaapi", "av1_vulkan"])
        case "H.265/HEVC":
            return opts(["libx265", "hevc_videotoolbox", "hevc_nvenc", "hevc_qsv", "hevc_amf", "hevc_d3d12va", "hevc_vaapi", "hevc_vulkan", "libkvazaar"])
        case "H.264/AVC":
            return opts(["libx264", "h264_videotoolbox", "h264_nvenc", "h264_qsv", "h264_amf", "h264_d3d12va", "h264_vaapi", "h264_vulkan"])
        case "来自 Apple":
            return opts(["h264_videotoolbox", "hevc_videotoolbox", "prores_videotoolbox", "prores_ks", "prores_aw"])
        case "来自 Google":
            return opts(["libvpx-vp9", "libsvt_vp9", "vp9_qsv", "vp9_vaapi", "libvpx", "vp8_vaapi"])
        case "FFV1":
            return opts(["ffv1 -level 3", "ffv1 -level 1", "ffv1_vulkan"])
        case "其他现代编码":
            return opts(["libxeve", "libxavs", "libxavs2", "cfhd"])
        case "老旧编码":
            return opts(["mpeg4", "libxvid", "rv20", "rv10", "wmv2", "wmv1"])
        case "禁用":
            return opts([""])
        default:
            return opts(["copy", "libx264", "libx265", "h264_videotoolbox", "hevc_videotoolbox", "prores_videotoolbox", "libsvtav1", "libaom-av1", "prores_ks", "ffv1"])
        }
    }

    static func profile(for encoder: String, probedCapabilities: [String: VideoEncoderCapability] = [:]) -> VideoEncoderProfile {
        if let capability = VideoEncoderCapabilityCatalog.capability(for: encoder, probed: probedCapabilities) {
            return VideoEncoderProfile(
                presets: opts(capability.presets),
                profiles: opts(capability.profiles),
                tunes: opts(capability.tunes),
                pixelFormats: opts(capability.pixelFormats)
            )
        }

        let data = videoEncoderProfiles[encoder] ?? VideoEncoderProfile(
            presets: opts(["", "veryslow", "slower", "slow", "medium", "fast", "faster", "veryfast", "superfast", "ultrafast"]),
            profiles: opts(["", "main", "high", "main10"]),
            tunes: opts(["", "film", "animation", "grain", "fastdecode", "zerolatency", "hq", "ll", "ull", "lossless"]),
            pixelFormats: opts(commonPixelFormats)
        )
        return data
    }

    static func presetInfo(for encoder: String) -> ParameterFieldInfo {
        if VideoEncoderCapabilityCatalog.isVideoToolboxEncoder(encoder) {
            return ParameterFieldInfo(
                title: videoPreset.title,
                placeholder: "不适用 VideoToolbox",
                help: "VideoToolbox 不使用 x264/x265 的 -preset；如旧预设保留此值，命令生成时会跳过。",
                options: [ParameterOption(title: "不适用 VideoToolbox", value: "")]
            )
        }
        return videoPreset
    }

    static func tuneInfo(for encoder: String) -> ParameterFieldInfo {
        if VideoEncoderCapabilityCatalog.isVideoToolboxEncoder(encoder) {
            return ParameterFieldInfo(
                title: videoTune.title,
                placeholder: "不适用 VideoToolbox",
                help: "VideoToolbox 不使用 x264/x265 的 -tune；低延迟请在进阶参数中使用 -realtime 1 等 VT 参数。",
                options: [ParameterOption(title: "不适用 VideoToolbox", value: "")]
            )
        }
        return videoTune
    }

    static func gpuInfo(for encoder: String) -> ParameterFieldInfo {
        if VideoEncoderCapabilityCatalog.isVideoToolboxEncoder(encoder) {
            return ParameterFieldInfo(
                title: videoGPU.title,
                placeholder: "不适用 VideoToolbox",
                help: "VideoToolbox 由 macOS 选择可用硬件，不支持 FFmpeg 的 -gpu 选择语义；命令生成时会跳过。",
                options: [ParameterOption(title: "不适用 VideoToolbox", value: "")]
            )
        }
        return videoGPU
    }

    static func threadsInfo(for encoder: String) -> ParameterFieldInfo {
        if VideoEncoderCapabilityCatalog.isVideoToolboxEncoder(encoder) {
            return ParameterFieldInfo(
                title: videoThreads.title,
                placeholder: "不适用 VideoToolbox",
                help: "VideoToolbox 编码器线程能力由系统管理，不支持手动 -threads:v；命令生成时会跳过。",
                options: [ParameterOption(title: "不适用 VideoToolbox", value: "")]
            )
        }
        return videoThreads
    }

    static func bitrateControlInfo(for encoder: String, probedCapabilities: [String: VideoEncoderCapability] = [:]) -> ParameterFieldInfo {
        if let capability = VideoEncoderCapabilityCatalog.capability(for: encoder, probed: probedCapabilities) {
            return ParameterFieldInfo(
                title: bitrateControl.title,
                placeholder: "VideoToolbox 控制方式",
                help: "VideoToolbox 不使用 CRF/CQ/QP 模型；优先使用 -q:v、-b:v、-maxrate/-bufsize 或 -constant_bit_rate 1。",
                options: opts(capability.bitrateControlModes)
            )
        }
        return bitrateControl
    }

    static func qualityArgumentInfo(for encoder: String, probedCapabilities: [String: VideoEncoderCapability] = [:]) -> ParameterFieldInfo {
        if let capability = VideoEncoderCapabilityCatalog.capability(for: encoder, probed: probedCapabilities) {
            return ParameterFieldInfo(
                title: qualityArgument.title,
                placeholder: "VideoToolbox 建议 -q:v",
                help: "VideoToolbox 质量控制建议使用 -q:v；CRF/CQ/QP 是其他编码器语义，不再作为 VT 候选。",
                options: opts(capability.qualityArguments)
            )
        }
        return qualityArgument
    }

    static func qualityValueInfo(for encoder: String, probedCapabilities: [String: VideoEncoderCapability] = [:]) -> ParameterFieldInfo {
        if let capability = VideoEncoderCapabilityCatalog.capability(for: encoder, probed: probedCapabilities) {
            return ParameterFieldInfo(
                title: qualityValue.title,
                placeholder: "例如 45 / 50 / 55 / 60 / 65",
                help: "VideoToolbox 的 -q:v 可作为质量倾向；实际效果受系统编码器、码率约束和输入格式影响。",
                options: opts(capability.qualityValues)
            )
        }
        return qualityValue
    }

    static func advancedQualityInfo(for encoder: String, probedCapabilities: [String: VideoEncoderCapability] = [:]) -> ParameterFieldInfo {
        if let capability = VideoEncoderCapabilityCatalog.capability(for: encoder, probed: probedCapabilities) {
            return ParameterFieldInfo(
                title: advancedQuality.title,
                placeholder: "-realtime 1 / -allow_sw 1 / -tag:v hvc1",
                help: "VideoToolbox 专属参数会拼接到视频参数末尾；下拉候选来自静态表，并会用本机 ffmpeg 探测结果过滤。",
                options: opts(capability.advancedQualityArguments)
            )
        }
        return advancedQuality
    }

    private static let videoEncoderProfiles: [String: VideoEncoderProfile] = [
        "copy": VideoEncoderProfile(presets: opts([""]), profiles: opts([""]), tunes: opts([""]), pixelFormats: opts([""])),
        "libx264": VideoEncoderProfile(presets: opts(["veryslow", "slower", "slow", "medium", "fast", "faster", "veryfast", "superfast", "ultrafast"]), profiles: opts(["baseline", "main", "high", "high10", "high422", "high444"]), tunes: opts(["film", "animation", "grain", "stillimage", "psnr", "ssim", "fastdecode", "zerolatency"]), pixelFormats: opts("yuv420p yuvj420p yuv422p yuvj422p yuv444p yuvj444p nv12 nv16 nv21 yuv420p10le yuv422p10le yuv444p10le nv20le gray gray10le")),
        "libx265": VideoEncoderProfile(presets: opts(["veryslow", "slower", "slow", "medium", "fast", "faster", "veryfast", "superfast", "ultrafast"]), profiles: opts(["main", "mainstillpicture"]), tunes: opts(["psnr", "ssim", "grain", "fastdecode", "zerolatency", "animation", "stillimage"]), pixelFormats: opts("yuv420p yuvj420p yuv422p yuvj422p yuv444p yuvj444p gbrp yuv420p10le yuv422p10le yuv444p10le gbrp10le yuv420p12le yuv422p12le yuv444p12le gbrp12le gray gray10le gray12le yuva420p yuva420p10le")),
        "libsvtav1": VideoEncoderProfile(presets: opts(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13"]), profiles: opts(["main", "high", "professional"]), tunes: opts([""]), pixelFormats: opts(["yuv420p", "yuv420p10le"])),
        "libaom-av1": VideoEncoderProfile(presets: opts(["0", "1", "2", "3", "4", "5", "6", "7", "8"]), profiles: opts(["0", "1", "2"]), tunes: opts(["psnr", "ssim", "qmt"]), pixelFormats: opts("yuv420p yuv422p yuv444p gbrp yuv420p10le yuv422p10le yuv444p10le yuv420p12le yuv422p12le yuv444p12le gbrp10le gbrp12le gray gray10le gray12le")),
        "h264_videotoolbox": VideoEncoderProfile(presets: opts([""]), profiles: opts(["baseline", "constrained_baseline", "main", "high", "constrained_high", "extended"]), tunes: opts([""]), pixelFormats: opts(["nv12", "yuv420p"])),
        "hevc_videotoolbox": VideoEncoderProfile(presets: opts([""]), profiles: opts(["main", "main10", "main42210", "rext"]), tunes: opts([""]), pixelFormats: opts(["nv12", "yuv420p", "bgra", "ayuv", "p010le", "p210le"])),
        "prores_videotoolbox": VideoEncoderProfile(presets: opts([""]), profiles: opts(["auto", "proxy", "lt", "standard", "hq", "4444", "xq"]), tunes: opts([""]), pixelFormats: opts(["yuv420p", "nv12", "ayuv64le", "uyvy422", "p010le", "nv16", "p210le", "p216le", "nv24", "p410le", "p416le", "bgra"])),
        "h264_nvenc": VideoEncoderProfile(presets: opts(["p7", "p6", "p5", "p4", "p3", "p2", "p1"]), profiles: opts(["baseline", "main", "high", "high10", "high422", "high444p"]), tunes: opts(["hq", "ll", "ull", "lossless"]), pixelFormats: opts("yuv420p nv12 p010le yuv444p p016le nv16 p210le p216le yuv444p16le bgr0 bgra rgb0 rgba x2rgb10le x2bgr10le gbrp gbrp16le cuda d3d11")),
        "hevc_nvenc": VideoEncoderProfile(presets: opts(["p7", "p6", "p5", "p4", "p3", "p2", "p1"]), profiles: opts(["main", "rext"]), tunes: opts(["hq", "uhq", "ll", "ull", "lossless"]), pixelFormats: opts("yuv420p nv12 p010le yuv444p p016le nv16 p210le p216le yuv444p16le bgr0 bgra rgb0 rgba x2rgb10le x2bgr10le gbrp gbrp16le cuda d3d11")),
        "h264_qsv": VideoEncoderProfile(presets: opts(["veryslow", "slower", "slow", "medium", "fast", "faster", "veryfast"]), profiles: opts(["baseline", "main", "high"]), tunes: opts([""]), pixelFormats: opts(["nv12", "qsv"])),
        "hevc_qsv": VideoEncoderProfile(presets: opts(["veryslow", "slower", "slow", "medium", "fast", "faster", "veryfast"]), profiles: opts(["main", "mainsp", "rext", "scc"]), tunes: opts([""]), pixelFormats: opts("nv12 p010le p012le yuyv422 y210le qsv bgra x2rgb10le vuyx xv30le")),
        "h264_amf": VideoEncoderProfile(presets: opts(["quality", "balanced", "speed"]), profiles: opts(["main", "high", "constrained_baseline", "constrained_high"]), tunes: opts(["transcoding", "ultralowlatency", "lowlatency", "webcam", "high_quality", "lowlatency_high_quality"]), pixelFormats: opts("nv12 yuv420p d3d11 dxva2_vld p010le amf bgr0 rgb0 bgra argb rgba x2bgr10le rgbaf16le")),
        "hevc_amf": VideoEncoderProfile(presets: opts(["quality", "balanced", "speed"]), profiles: opts(["main"]), tunes: opts(["transcoding", "ultralowlatency", "lowlatency", "webcam", "high_quality", "lowlatency_high_quality"]), pixelFormats: opts("nv12 yuv420p d3d11 dxva2_vld p010le amf bgr0 rgb0 bgra argb rgba x2bgr10le rgbaf16le")),
        "libvvenc": VideoEncoderProfile(presets: opts(["slower", "slow", "medium", "fast", "faster"]), profiles: opts(["main", "main10"]), tunes: opts([""]), pixelFormats: opts(["yuv420p", "yuv420p10le"])),
        "libx266": VideoEncoderProfile(presets: opts(["veryslow", "slower", "slow", "medium", "fast", "faster", "veryfast", "superfast", "ultrafast"]), profiles: opts(["main", "main10"]), tunes: opts([""]), pixelFormats: opts(["yuv420p", "yuv420p10le"])),
        "prores_ks": VideoEncoderProfile(presets: opts([""]), profiles: opts(["auto", "proxy", "lt", "standard", "hq", "4444", "4444xq"]), tunes: opts([""]), pixelFormats: opts(["yuv422p10le", "yuv444p10le", "yuva444p10le"])),
        "prores_aw": VideoEncoderProfile(presets: opts([""]), profiles: opts(["auto", "proxy", "lt", "standard", "hq", "4444", "4444xq"]), tunes: opts([""]), pixelFormats: opts(["yuv422p10le", "yuv444p10le", "yuva444p10le"])),
        "libvpx-vp9": VideoEncoderProfile(presets: opts(["0", "1", "2", "3", "4", "5"]), profiles: opts([""]), tunes: opts(["psnr", "ssim"]), pixelFormats: opts("yuv420p yuva420p yuv422p yuv440p yuv444p yuv420p10le yuv422p10le yuv440p10le yuv444p10le yuv420p12le yuv422p12le yuv440p12le yuv444p12le gbrp gbrp10le gbrp12le")),
        "libsvt_vp9": VideoEncoderProfile(presets: opts(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]), profiles: opts([""]), tunes: opts(["vq", "ssim", "vmaf"]), pixelFormats: opts(["yuv420p"]))
    ]

    private static let commonPixelFormats = ["", "yuv420p", "yuv420p10le", "yuv422p", "yuv422p10le", "yuv444p", "yuv444p10le", "nv12", "p010le", "gbrp", "gray"]

    private static func opts(_ values: [String]) -> [ParameterOption] {
        values.map(ParameterOption.init)
    }

    private static func opts(_ values: String) -> [ParameterOption] {
        opts(values.split(separator: " ").map(String.init))
    }
}

private func normalizeOptionNameInput(_ value: String) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, !trimmed.hasPrefix("-") else { return trimmed }
    return "-" + trimmed
}

private struct OverviewPane: View {
    @Binding var preset: PresetData
    private let builder = FFmpegCommandBuilder()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("参数总览")
                .font(.title2.weight(.semibold))
            Text(builder.overview(preset: preset))
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
            Text("实际命令行")
                .font(.headline)
            Text(builder.build(preset: preset, input: "<InputFile>", output: "<OutputFile>"))
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
    }
}

private struct OutputSettingsPane: View {
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

private struct DecodingPane: View {
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

private struct VideoEncoderPane: View {
    @Binding var preset: PresetData
    var probedCapabilities: [String: VideoEncoderCapability]

    private var profile: VideoEncoderProfile {
        ParameterOptionCatalog.profile(for: preset.videoEncoder, probedCapabilities: probedCapabilities)
    }

    private var sectionNote: String {
        if VideoEncoderCapabilityCatalog.isVideoToolboxEncoder(preset.videoEncoder) {
            return "VideoToolbox 使用 macOS 系统硬件编码，不支持 x264/x265 的 preset/tune/CRF 语义。质量优先使用 -q:v 或码率参数；低延迟使用 -realtime 1。"
        }
        return "视频编码器通用配置；部分编码器的参数名有区别，会自动使用对应参数名。以上三个参数还有很多值尚未收录，欢迎反馈补充和修正。"
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
            FormRow(label: "配置文件", help: ParameterOptionCatalog.videoProfile.help) {
                FieldComboBox(text: $preset.videoProfile, info: ParameterOptionCatalog.videoProfile, options: profile.profiles)
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

private struct VideoFramePane: View {
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

private struct VideoQualityPane: View {
    @Binding var preset: PresetData
    var probedCapabilities: [String: VideoEncoderCapability]

    private var sectionNote: String {
        if VideoEncoderCapabilityCatalog.isVideoToolboxEncoder(preset.videoEncoder) {
            return "VideoToolbox 不使用软件编码器的 CRF/CQ/QP 模型。建议用 -q:v 表示质量倾向，或用 -b:v、-maxrate、-bufsize 做码率控制。"
        }
        return "传统的转码直接指定数据速率；对于压制工作通常不考虑。基础比特率与全局质量控制可能冲突。"
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
            FormRow(label: "最高值") {
                FieldComboBox(text: $preset.bitrateMax, info: ParameterOptionCatalog.bitrateMax)
            }
            FormRow(label: "缓冲区") {
                FieldComboBox(text: $preset.bitrateBuffer, info: ParameterOptionCatalog.bitrateBuffer)
            }
            FormRow(label: "进阶参数集", help: ParameterOptionCatalog.advancedQualityInfo(for: preset.videoEncoder, probedCapabilities: probedCapabilities).help) {
                FieldComboBox(text: stringArrayBinding($preset.advancedQualityArguments), info: ParameterOptionCatalog.advancedQualityInfo(for: preset.videoEncoder, probedCapabilities: probedCapabilities))
            }
        }
    }
}

private struct ColorPane: View {
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

private struct CommonFiltersPane: View {
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

private struct FrameServerPane: View {
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

private struct AudioPane: View {
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

private struct ImageParametersPane: View {
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

private struct CustomArgumentsPane: View {
    @Binding var preset: PresetData

    var body: some View {
        FormSection(title: "自定义参数", note: "为各种细分领域和深度专业人士提供最大程度的自由。注意：所有换行都不会生效！") {
            FormRow(label: "视频滤镜") { FieldComboBox(text: $preset.customVideoFilter, info: ParameterOptionCatalog.customVideoFilter) }
            FormRow(label: "音频滤镜") { FieldComboBox(text: $preset.customAudioFilter, info: ParameterOptionCatalog.customAudioFilter) }
            FormRow(label: "filter_complex") { FieldComboBox(text: $preset.customFilterComplex, info: ParameterOptionCatalog.customFilterComplex) }
            FormRow(label: "视频参数") { FieldComboBox(text: $preset.customVideoArguments, info: ParameterOptionCatalog.customVideoArguments) }
            FormRow(label: "音频参数") { FieldComboBox(text: $preset.customAudioArguments, info: ParameterOptionCatalog.customAudioArguments) }
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

private struct ClipPane: View {
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

private struct StreamControlPane: View {
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

private struct SchemeManagementPane: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var presetStore: PresetStore
    @Binding var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("方案管理")
                .font(.title2.weight(.semibold))
            Text("不保证跨版本通用，使用非当前版本则某些设置可能未还原，版本相差过大或早期版本会直接报错。\n选中项进行操作；双击快速读取；重复选中进入编辑模式来重命名。\n选中时进行保存是覆盖到选中，不选中时会新建，删除直接手动删文件即可，位于根目录下的 Preset 文件夹。")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
            HStack {
                Button("新建方案") { presetStore.reset() }
                Button("导入 .3fui / JSON") { appState.presentPresetImportPanel() }
                Button("导出 .3fui") { appState.presentPresetExportPanel() }
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
}

private func stringArrayBinding(_ binding: Binding<[String]>) -> Binding<String> {
    Binding<String>(
        get: { binding.wrappedValue.joined(separator: ",") },
        set: {
            binding.wrappedValue = $0.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
    )
}
