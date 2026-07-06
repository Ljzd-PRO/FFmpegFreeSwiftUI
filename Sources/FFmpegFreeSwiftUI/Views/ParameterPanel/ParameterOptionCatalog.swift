import Foundation

enum ParameterOptionCatalog {
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
    static let bitrateBase = ParameterFieldInfo(title: "比特率基础", placeholder: "-b:v", help: "VideoToolbox 控制文件大小的主参数；记得带单位，例如 5000k、5M。大小可粗略估算为：码率 Mbps × 时长分钟 × 7.5。")
    static let bitrateMin = ParameterFieldInfo(title: "最低值", placeholder: "-minrate")
    static let bitrateMax = ParameterFieldInfo(title: "最高值", placeholder: "-maxrate", help: "限制峰值码率；用于播放兼容或直播。普通转码可留空，填写时通常为 -b:v 的 1.5 到 2 倍。")
    static let bitrateBuffer = ParameterFieldInfo(title: "缓冲区", placeholder: "-bufsize", help: "与 -maxrate 配合使用，影响码率波动缓冲。普通转码可留空，填写时通常为 -b:v 的 2 倍左右。")
    static let advancedQuality = ParameterFieldInfo(title: "进阶参数集", placeholder: "-x265-params key=value 或多个参数", help: "添加预制或空项然后编辑参数；编码器内部小参可在自定义参数里写。")
    static let videoToolboxBitrate = ParameterFieldInfo(
        title: "视频码率 (-b:v)",
        placeholder: "例如 5M / 8000k",
        help: "控制文件大小的主参数。大小可粗略估算为：码率 Mbps × 时长分钟 × 7.5。",
        options: [
            ParameterOption(title: "", value: ""),
            ParameterOption(title: "720p30 小体积 2500k", value: "2500k"),
            ParameterOption(title: "720p30 清晰 4M", value: "4M"),
            ParameterOption(title: "1080p30 小体积 6M", value: "6M"),
            ParameterOption(title: "1080p30 清晰 8M", value: "8M"),
            ParameterOption(title: "1080p60 平衡 12M", value: "12M"),
            ParameterOption(title: "4K30 HEVC 平衡 25M", value: "25M"),
            ParameterOption(title: "4K60 HEVC 平衡 45M", value: "45M")
        ]
    )
    static let videoToolboxQualityValue = ParameterFieldInfo(
        title: "质量等级 (-q:v)",
        placeholder: "推荐 65",
        help: "50 偏小，65 平衡，75 高质量，80 以上文件会明显变大。",
        options: opts(["", "50", "55", "65", "75", "80"])
    )
    static let videoToolboxMinrate = ParameterFieldInfo(title: "最低码率 (-minrate)", placeholder: "通常留空", help: "普通转码通常不需要最低码率；只有平台明确要求码率范围时再填写。")
    static let videoToolboxMaxrate = ParameterFieldInfo(title: "峰值码率 (-maxrate)", placeholder: "例如 8M / 12000k", help: "限制峰值码率；用于播放兼容或直播。普通转码可留空，填写时通常为 -b:v 的 1.5 到 2 倍。")
    static let videoToolboxBufsize = ParameterFieldInfo(title: "缓冲区 (-bufsize)", placeholder: "例如 10M / 16000k", help: "与 -maxrate 配合使用，影响码率波动缓冲。普通转码可留空，填写时通常为 -b:v 的 2 倍左右。")

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
                presets: capability.supportsPreset ? opts(capability.presets) : [videoToolboxNotApplicableOption],
                profiles: opts(capability.profiles),
                tunes: capability.supportsTune ? opts(capability.tunes) : [videoToolboxNotApplicableOption],
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
                options: [videoToolboxNotApplicableOption]
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
                options: [videoToolboxNotApplicableOption]
            )
        }
        return videoTune
    }

    static func profileInfo(for encoder: String) -> ParameterFieldInfo {
        switch VideoToolboxEncoderKind(encoder: encoder) {
        case .h264:
            return ParameterFieldInfo(
                title: videoProfile.title,
                placeholder: "-profile:v",
                help: "H.264 VideoToolbox 常用 high；老设备兼容可选 main 或 baseline。它不是画质滑杆，主要影响兼容规格。"
            )
        case .hevc:
            return ParameterFieldInfo(
                title: videoProfile.title,
                placeholder: "-profile:v",
                help: "HEVC VideoToolbox 普通 8-bit 视频选 main；10-bit/HDR 输入可选 main10 并配合 p010le。"
            )
        case .prores:
            return ParameterFieldInfo(
                title: videoProfile.title,
                placeholder: "ProRes 档位",
                help: "ProRes 的 profile 是主要质量/大小档位：proxy 最小，lt 较小，standard 标准，hq 更高，4444/xq 文件很大。"
            )
        case .none:
            return videoProfile
        }
    }

    static func gpuInfo(for encoder: String) -> ParameterFieldInfo {
        if VideoEncoderCapabilityCatalog.isVideoToolboxEncoder(encoder) {
            return ParameterFieldInfo(
                title: videoGPU.title,
                placeholder: "不适用 VideoToolbox",
                help: "VideoToolbox 由 macOS 选择可用硬件，不支持 FFmpeg 的 -gpu 选择语义；命令生成时会跳过。",
                options: [videoToolboxNotApplicableOption]
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
                options: [videoToolboxNotApplicableOption]
            )
        }
        return videoThreads
    }

    static func bitrateControlInfo(for encoder: String, probedCapabilities: [String: VideoEncoderCapability] = [:]) -> ParameterFieldInfo {
        if let capability = VideoEncoderCapabilityCatalog.capability(for: encoder, probed: probedCapabilities) {
            if VideoToolboxEncoderKind(encoder: encoder) == .prores {
                return ParameterFieldInfo(
                    title: bitrateControl.title,
                    placeholder: "ProRes profile 控制质量档位",
                    help: "ProRes 的文件大小主要由 profile 档位决定，不建议用 -b:v 或 -q:v 来压小文件。",
                    options: opts(capability.bitrateControlModes)
                )
            }
            return ParameterFieldInfo(
                title: bitrateControl.title,
                placeholder: "VideoToolbox 控制方式",
                help: "想控制文件大小选 -b:v；想省心控制画质选 -q:v 65。CRF/CQ/QP 是其他编码器语义，不建议用于 VT。",
                options: opts(capability.bitrateControlModes)
            )
        }
        return bitrateControl
    }

    static func qualityArgumentInfo(for encoder: String, probedCapabilities: [String: VideoEncoderCapability] = [:]) -> ParameterFieldInfo {
        if let capability = VideoEncoderCapabilityCatalog.capability(for: encoder, probed: probedCapabilities) {
            if VideoToolboxEncoderKind(encoder: encoder) == .prores {
                return ParameterFieldInfo(
                    title: qualityArgument.title,
                    placeholder: "通常留空",
                    help: "ProRes VideoToolbox 使用 profile 档位控制质量和大小；这里通常不填写。",
                    options: opts(capability.qualityArguments)
                )
            }
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
            if VideoToolboxEncoderKind(encoder: encoder) == .prores {
                return ParameterFieldInfo(
                    title: qualityValue.title,
                    placeholder: "通常留空",
                    help: "ProRes 的质量值通常不填；请在编码器页选择 proxy、lt、standard、hq、4444 或 xq。",
                    options: opts(capability.qualityValues)
                )
            }
            return ParameterFieldInfo(
                title: qualityValue.title,
                placeholder: "例如 50 / 65 / 75 / 80",
                help: "VideoToolbox 的 -q:v 可作为质量倾向：50 偏小，65 平衡，75 高质量，80 以上文件会明显变大。",
                options: opts(capability.qualityValues)
            )
        }
        return qualityValue
    }

    static func advancedQualityInfo(for encoder: String, probedCapabilities: [String: VideoEncoderCapability] = [:]) -> ParameterFieldInfo {
        if let capability = VideoEncoderCapabilityCatalog.capability(for: encoder, probed: probedCapabilities) {
            if VideoToolboxEncoderKind(encoder: encoder) == .prores {
                return ParameterFieldInfo(
                    title: advancedQuality.title,
                    placeholder: "通常留空",
                    help: "ProRes VideoToolbox 的质量和大小主要由 profile 档位决定；这里的实时、省电、软编选项通常不需要填写。",
                    options: opts(capability.advancedQualityArguments)
                )
            }
            return ParameterFieldInfo(
                title: advancedQuality.title,
                placeholder: "-realtime 1 / -allow_sw 1 / -tag:v hvc1",
                help: "VideoToolbox 专属参数会拼接到视频参数末尾；普通转码通常留空，直播/录屏才考虑 -realtime 1。",
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
    private static let videoToolboxNotApplicableOption = ParameterOption(title: "不适用 VideoToolbox", value: "", clearsToPlaceholder: true)

    private static func opts(_ values: [String]) -> [ParameterOption] {
        values.map(ParameterOption.init)
    }

    private static func opts(_ values: String) -> [ParameterOption] {
        opts(values.split(separator: " ").map(String.init))
    }
}
