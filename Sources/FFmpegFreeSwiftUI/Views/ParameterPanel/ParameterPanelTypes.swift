import SwiftUI

enum ParameterTab: String, CaseIterable, Identifiable {
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

    func title(language: String) -> String {
        L10n.text(rawValue, language: language)
    }
}

@MainActor
final class VideoEncoderCapabilityStore: ObservableObject {
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
