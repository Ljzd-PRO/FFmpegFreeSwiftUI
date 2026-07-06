import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settingsStore: SettingsStore
    @State private var detectedLocations: [FFmpegToolLocation] = []
    @State private var pathMessage = ""

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(t("设置"))
                    .font(.title2.weight(.semibold))

                settingsSection("性能调度") {
                    Stepper(value: $settingsStore.settings.maxConcurrentTasks, in: 1...10) {
                        Text("\(t("自动同时运行任务数量")): \(settingsStore.settings.maxConcurrentTasks)")
                    }
                    HStack {
                        Text(t("编码队列刷新速度"))
                        Slider(value: $settingsStore.settings.queueRefreshInterval, in: 0.2...2.0)
                        Text(String(format: "%.1fs", settingsStore.settings.queueRefreshInterval))
                    }
                    TextField(t("指定处理器核心（保留设置，macOS 首版不绑定 affinity）"), text: $settingsStore.settings.selectedProcessorCores)
                }

                settingsSection("功能设定") {
                    Toggle(t("自动开始任务"), isOn: $settingsStore.settings.autoStartTasks)
                    Toggle(t("启用提示音"), isOn: $settingsStore.settings.soundEnabled)
                    Toggle(t("自动重置参数面板到第一个页面"), isOn: $settingsStore.settings.resetParameterPanelOnStart)
                    Toggle(t("任务名称混淆"), isOn: $settingsStore.settings.obfuscateTaskName)
                    Stepper(value: $settingsStore.settings.deleteFailedOutputPolicy, in: 0...2) {
                        Text("\(t("任务失败删除输出文件策略")): \(settingsStore.settings.deleteFailedOutputPolicy)")
                    }
                    TextField(t("工作目录"), text: $settingsStore.settings.workingDirectory)
                }

                settingsSection("FFmpeg 路径") {
                    Text(t("自动检测会按用户设置、App 同级目录、PATH 和常见安装目录查找；留空自定义路径时也会自动使用检测到的位置。"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Button(t("自动检测")) { refreshDetectedLocations(message: "已刷新检测结果") }
                        Button(t("写入检测结果")) { applyDetectedLocations() }
                        Button(t("清空自定义路径")) { clearCustomPaths() }
                    }
                    .buttonStyle(.bordered)
                    if !pathMessage.isEmpty {
                        Text(t(pathMessage))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    detectionTable
                    TextField(t("替代 ffmpeg 文件名"), text: $settingsStore.settings.ffmpegExecutableOverride)
                    TextField(t("替代 ffprobe 文件名"), text: $settingsStore.settings.ffprobeExecutableOverride)
                    TextField(t("替代 ffplay 文件名"), text: $settingsStore.settings.ffplayExecutableOverride)
                    TextField(t("覆盖参数传递，使用 <args>"), text: $settingsStore.settings.argumentPassthroughTemplate)
                }

                settingsSection("远程调用") {
                    Toggle(t("启用 UDP 监听"), isOn: $settingsStore.settings.remoteCallEnabled)
                    TextField(t("端口"), text: $settingsStore.settings.remotePort)
                    Button(t("应用远程调用设置")) {
                        appState.remoteServer.update(enabled: settingsStore.settings.remoteCallEnabled, port: settingsStore.settings.remotePort)
                    }
                    Text(appState.remoteServer.lastMessage)
                        .foregroundStyle(.secondary)
                }

                displaySection

                aboutSection
            }
            .padding(24)
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            refreshDetectedLocations()
        }
        .onChange(of: settingsStore.settings.ffmpegExecutableOverride) { _ in refreshDetectedLocations() }
        .onChange(of: settingsStore.settings.ffprobeExecutableOverride) { _ in refreshDetectedLocations() }
        .onChange(of: settingsStore.settings.ffplayExecutableOverride) { _ in refreshDetectedLocations() }
    }

    private var detectionTable: some View {
        Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 6) {
            GridRow {
                Text(t("命令行工具")).font(.caption.weight(.semibold))
                Text(t("状态")).font(.caption.weight(.semibold))
                Text(t("来源")).font(.caption.weight(.semibold))
                Text(t("路径")).font(.caption.weight(.semibold))
            }
            Divider().gridCellColumns(4)
            ForEach(detectedLocations, id: \.tool) { location in
                GridRow {
                    Text(location.tool.rawValue)
                        .font(.system(.body, design: .monospaced))
                    Label(t(location.isExecutable ? "可执行" : "不可执行"), systemImage: location.isExecutable ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(location.isExecutable ? .green : .secondary)
                    Text(t(sourceTitle(location.source)))
                        .foregroundStyle(.secondary)
                    Text(location.path)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .lineLimit(2)
                }
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var normalizedLanguageBinding: Binding<String> {
        Binding(
            get: { AppLanguage.normalize(settingsStore.settings.language).rawValue },
            set: { settingsStore.settings.language = AppLanguage.normalize($0).rawValue }
        )
    }

    private var appearanceBinding: Binding<String> {
        Binding(
            get: { AppAppearanceMode.normalize(settingsStore.settings.appearanceMode).rawValue },
            set: { settingsStore.settings.appearanceMode = AppAppearanceMode.normalize($0).rawValue }
        )
    }

    private var densityBinding: Binding<String> {
        Binding(
            get: { AppInterfaceDensity.normalize(settingsStore.settings.interfaceDensity).rawValue },
            set: { settingsStore.settings.interfaceDensity = AppInterfaceDensity.normalize($0).rawValue }
        )
    }

    private var fontSizeBinding: Binding<Double> {
        Binding(
            get: { settingsStore.settings.baseFontSize },
            set: { settingsStore.settings.baseFontSize = max(11, min(18, $0)) }
        )
    }

    private var displaySection: some View {
        settingsSection("界面显示") {
            Text(t("这些设置会立即应用到主窗口；字体名称留空或填 System 表示使用系统默认字体。"))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Text(t("语言"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Picker(t("语言"), selection: normalizedLanguageBinding) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(t(language.displayName)).tag(language.rawValue)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(t("外观"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Picker(t("外观"), selection: appearanceBinding) {
                    ForEach(AppAppearanceMode.allCases) { mode in
                        Text(t(mode.titleKey)).tag(mode.rawValue)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(t("界面密度"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Picker(t("界面密度"), selection: densityBinding) {
                    ForEach(AppInterfaceDensity.allCases) { density in
                        Text(t(density.titleKey)).tag(density.rawValue)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 10) {
                GridRow {
                    Text(t("全局字体"))
                        .foregroundStyle(.secondary)
                        .frame(width: 130, alignment: .leading)
                    TextField("System", text: $settingsStore.settings.fontName)
                        .frame(maxWidth: 360)
                }
                GridRow {
                    Text(t("基础字号"))
                        .foregroundStyle(.secondary)
                        .frame(width: 130, alignment: .leading)
                    HStack {
                        Slider(value: fontSizeBinding, in: 11...18, step: 1)
                            .frame(maxWidth: 300)
                        Stepper(value: fontSizeBinding, in: 11...18, step: 1) {
                            Text("\(Int(settingsStore.settings.baseFontSize)) pt")
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                }
            }

            displayPreview
        }
    }

    private var displayPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "textformat.size")
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 3) {
                    Text(t("显示预览"))
                        .font(.headline)
                    Text(t("编码队列、参数面板和工具页面会使用当前显示偏好。"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(t(AppInterfaceDensity.normalize(settingsStore.settings.interfaceDensity).titleKey))
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(Capsule())
            }
            HStack(spacing: 10) {
                previewChip("编码队列", icon: "list.bullet.rectangle")
                previewChip("参数面板", icon: "slider.horizontal.3")
                previewChip("媒体信息", icon: "info.circle")
            }
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func previewChip(_ title: String, icon: String) -> some View {
        Label(t(title), systemImage: icon)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var aboutSection: some View {
        settingsSection("关于本应用") {
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 3) {
                    Text("FFmpegFreeSwiftUI")
                        .font(.headline)
                    Text(t("本机显示的版本号来自 App bundle，可用于反馈问题或核对发布包。"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
                GridRow {
                    Text(t("版本"))
                        .foregroundStyle(.secondary)
                        .frame(width: 130, alignment: .leading)
                    Text(AppVersion.shortDisplayString)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
                GridRow {
                    Text(t("构建"))
                        .foregroundStyle(.secondary)
                        .frame(width: 130, alignment: .leading)
                    Text(AppVersion.buildNumber)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
                GridRow {
                    Text(t("应用标识"))
                        .foregroundStyle(.secondary)
                        .frame(width: 130, alignment: .leading)
                    Text(AppVersion.bundleIdentifier)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
    }

    private func refreshDetectedLocations(message: String = "") {
        detectedLocations = FFmpegLocator(settings: settingsStore.settings).locations()
        if !message.isEmpty {
            pathMessage = message
        }
    }

    private func applyDetectedLocations() {
        refreshDetectedLocations()
        var applied = false
        for location in detectedLocations where location.isExecutable {
            switch location.tool {
            case .ffmpeg:
                settingsStore.settings.ffmpegExecutableOverride = location.path
            case .ffprobe:
                settingsStore.settings.ffprobeExecutableOverride = location.path
            case .ffplay:
                settingsStore.settings.ffplayExecutableOverride = location.path
            }
            applied = true
        }
        refreshDetectedLocations()
        pathMessage = applied ? "已写入可执行路径" : "没有找到可写入的可执行路径"
    }

    private func clearCustomPaths() {
        settingsStore.settings.ffmpegExecutableOverride = ""
        settingsStore.settings.ffprobeExecutableOverride = ""
        settingsStore.settings.ffplayExecutableOverride = ""
        refreshDetectedLocations()
        pathMessage = "已清空自定义路径"
    }

    private func sourceTitle(_ source: FFmpegLocationSource) -> String {
        switch source {
        case .userOverride:
            return "用户设置"
        case .appSibling:
            return "App 同级目录"
        case .pathEnvironment:
            return "环境变量 PATH"
        case .commonDirectory:
            return "常见安装目录"
        case .fallback:
            return "未找到"
        }
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(t(title))
                .font(.headline)
            content()
        }
        .frame(maxWidth: 860, alignment: .leading)
    }

    private func t(_ key: String) -> String {
        L10n.text(key, language: settingsStore.settings.language)
    }
}
