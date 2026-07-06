import SwiftUI

public struct StartPageView: View {
    @EnvironmentObject private var settingsStore: SettingsStore

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 16) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("FFmpegFreeSwiftUI")
                                .font(.largeTitle.weight(.semibold))
                            Text(AppVersion.shortDisplayString)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.accentColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.12))
                                .clipShape(Capsule())
                                .textSelection(.enabled)
                        }
                        Text(t("将 ffmpeg、ffplay、ffprobe 加入环境变量、放在 App 同级目录，或在设置中指定路径即可调用。"))
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text(t("主要逻辑"))
                        .font(.headline)
                    Text(t("先在参数面板设定选项，再把文件拖进编码队列。加入队列时会保存当前参数快照，任务开始时生成命令行。"))
                    Text(t("macOS 版使用原生 Process、Unix signal、Finder 定位、caffeinate 防睡眠和 JSON 预设。"))
                }

                LinkGridView(language: settingsStore.settings.language)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func t(_ key: String) -> String {
        L10n.text(key, language: settingsStore.settings.language)
    }
}

private struct LinkGridView: View {
    var language: String
    private let links: [(String, String)] = [
        ("3FUI GitHub 仓库", "https://github.com/Lake1059/FFmpegFreeUI"),
        ("FFmpeg 官方文档", "https://ffmpeg.org/documentation.html"),
        ("下载 FFmpeg", "https://ffmpeg.org/download.html"),
        ("官网 ffmpegfreeui.top", "https://ffmpegfreeui.top"),
        ("官网 3fui.top", "https://3fui.top")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.text("链接和文档", language: language))
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], alignment: .leading, spacing: 12) {
                ForEach(links, id: \.0) { label, url in
                    Link(destination: URL(string: url)!) {
                        Label(L10n.text(label, language: language), systemImage: "arrow.up.right.square")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}
