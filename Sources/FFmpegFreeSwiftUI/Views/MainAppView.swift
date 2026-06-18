import SwiftUI

public enum MainSection: String, CaseIterable, Identifiable {
    case start = "3FUI"
    case encodeQueue = "编码队列"
    case prepareFiles = "准备文件"
    case parameterPanel = "参数面板"
    case mediaInfo = "媒体信息"
    case player = "播放器"
    case quality = "画质评测"
    case muxing = "混流"
    case merging = "合并"
    case performance = "性能监控"
    case plugins = "插件扩展"
    case settings = "设置"
    case supporters = "支持者"

    public var id: String { rawValue }
}

public struct MainAppView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var presetStore: PresetStore
    @EnvironmentObject private var queueStore: EncodingQueueStore

    public init() {}

    public var body: some View {
        NavigationSplitView {
            List(selection: $appState.selectedSection) {
                Section("FFmpegFreeSwiftUI") {
                    ForEach(MainSection.allCases) { section in
                        NavigationLink(value: section) {
                            Label(section.rawValue, systemImage: icon(for: section))
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 210, ideal: 230)
        } detail: {
            Group {
                switch appState.selectedSection ?? .start {
                case .start:
                    StartPageView()
                case .encodeQueue:
                    EncodeQueueView()
                case .prepareFiles:
                    PrepareFilesView()
                case .parameterPanel:
                    ParameterPanelView()
                case .mediaInfo:
                    MediaInfoView()
                case .player:
                    FFplayView()
                case .quality:
                    QualityAssessmentView()
                case .muxing:
                    MuxingView()
                case .merging:
                    MergingView()
                case .performance:
                    PerformanceView()
                case .plugins:
                    PluginExtensionView()
                case .settings:
                    SettingsView()
                case .supporters:
                    SupportersView()
                }
            }
            .navigationTitle(appState.selectedSection?.rawValue ?? "FFmpegFreeSwiftUI")
        }
    }

    private func icon(for section: MainSection) -> String {
        switch section {
        case .start: return "house"
        case .encodeQueue: return "list.bullet.rectangle"
        case .prepareFiles: return "tray.and.arrow.down"
        case .parameterPanel: return "slider.horizontal.3"
        case .mediaInfo: return "info.circle"
        case .player: return "play.rectangle"
        case .quality: return "waveform.path.ecg.rectangle"
        case .muxing: return "rectangle.stack.badge.plus"
        case .merging: return "square.stack.3d.down.forward"
        case .performance: return "gauge.with.dots.needle.67percent"
        case .plugins: return "puzzlepiece.extension"
        case .settings: return "gearshape"
        case .supporters: return "heart"
        }
    }
}

public struct PlaceholderFeatureView: View {
    public var title: String
    public var message: String

    public init(title: String, message: String) {
        self.title = title
        self.message = message
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2.weight(.semibold))
            Text(message)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
