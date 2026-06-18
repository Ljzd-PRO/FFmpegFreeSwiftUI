import SwiftUI
#if !XCODE_APP
import FFmpegFreeSwiftUI
#endif

@main
struct FFmpegFreeSwiftUIExecutableApp: App {
    @StateObject private var appState = AppState()

    private var language: String {
        appState.settingsStore.settings.language
    }

    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environmentObject(appState)
                .environmentObject(appState.settingsStore)
                .environmentObject(appState.presetStore)
                .environmentObject(appState.queueStore)
                .environmentObject(appState.qualityStore)
                .font(appFont)
                .controlSize(controlSize)
                .preferredColorScheme(colorScheme)
                .frame(minWidth: 1200, minHeight: 700)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(t("添加文件到编码队列...")) {
                    appState.presentOpenPanelForQueue()
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
            CommandGroup(replacing: .importExport) {
                Button(t("导入预设...")) {
                    appState.presentPresetImportPanel()
                }
                .keyboardShortcut("o", modifiers: [.command, .option])
                Button(t("导出当前预设...")) {
                    appState.presentPresetExportPanel()
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
            }
            CommandGroup(replacing: .appSettings) {
                Button(t("设置...")) {
                    appState.navigate(to: .settings)
                }
                .keyboardShortcut(",", modifiers: [.command])
            }
            CommandGroup(replacing: .help) {
                Button(t("插件扩展")) { appState.navigate(to: .plugins) }
                Button(t("支持者")) { appState.navigate(to: .supporters) }
            }
            CommandMenu(t("导航")) {
                navigationButton(.start, shortcut: "1")
                navigationButton(.encodeQueue, shortcut: "2")
                navigationButton(.prepareFiles, shortcut: "3")
                navigationButton(.parameterPanel, shortcut: "4")
                navigationButton(.mediaInfo, shortcut: "5")
                navigationButton(.player, shortcut: "6")
                navigationButton(.quality, shortcut: "7")
                navigationButton(.muxing, shortcut: "8")
                navigationButton(.merging, shortcut: "9")
                navigationButton(.performance, shortcut: "0")
                Divider()
                navigationButton(.plugins)
                navigationButton(.settings)
                navigationButton(.supporters)
            }
            CommandMenu(t("编码队列")) {
                Button(t("添加文件...")) {
                    appState.presentOpenPanelForQueue()
                }
                Button(t("开始未处理任务")) {
                    appState.queueStore.startPending()
                }
                .keyboardShortcut("r", modifiers: [.command])
                Button(t("开始选中任务")) {
                    appState.queueStore.startSelected()
                }
                .disabled(appState.queueStore.selectedTask == nil)
                Button(t("暂停选中任务")) {
                    appState.queueStore.pauseSelected()
                }
                .disabled(appState.queueStore.selectedTask?.status != .running)
                Button(t("恢复选中任务")) {
                    appState.queueStore.resumeSelected()
                }
                .disabled(appState.queueStore.selectedTask?.status != .paused)
                Button(t("停止选中任务")) {
                    appState.queueStore.stopSelected()
                }
                .disabled(appState.queueStore.selectedTask == nil)
                Divider()
                Button(t("移除选中任务")) {
                    appState.queueStore.removeSelected()
                }
                .disabled(appState.queueStore.selectedTask == nil)
                Button(t("重置选中任务")) {
                    appState.queueStore.resetSelected()
                }
                .disabled(appState.queueStore.selectedTask == nil)
                Divider()
                Button(t("复制任务命令行")) {
                    appState.queueStore.copySelectedCommandLine()
                }
                .disabled(appState.queueStore.selectedTask == nil)
                Button(t("在 Finder 中显示输出")) {
                    appState.queueStore.revealSelectedOutput()
                }
                .disabled(appState.queueStore.selectedTask == nil)
            }
            CommandMenu(t("参数/预设")) {
                Button(t("重置当前参数")) {
                    appState.presetStore.reset()
                    appState.navigate(to: .parameterPanel)
                }
                Divider()
                Button(t("导入预设...")) {
                    appState.presentPresetImportPanel()
                    appState.navigate(to: .parameterPanel)
                }
                .keyboardShortcut("o", modifiers: [.command, .option])
                Button(t("导出当前预设...")) {
                    appState.presentPresetExportPanel()
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
                Divider()
                Button(t("参数面板覆盖到选中任务")) {
                    appState.queueStore.overwriteSelectedTaskPreset(with: appState.presetStore.current)
                    appState.navigate(to: .encodeQueue)
                }
                .disabled(appState.queueStore.selectedTask == nil)
                Button(t("选中任务参数覆盖到参数面板")) {
                    if let selectedTask = appState.queueStore.selectedTask {
                        appState.presetStore.loadFromTask(selectedTask)
                        appState.navigate(to: .parameterPanel)
                    }
                }
                .disabled(appState.queueStore.selectedTask?.preset == nil)
            }
            CommandMenu(t("工具")) {
                navigationButton(.mediaInfo)
                navigationButton(.player)
                navigationButton(.quality)
                Divider()
                navigationButton(.muxing)
                navigationButton(.merging)
                Divider()
                navigationButton(.performance)
            }
        }
    }

    @ViewBuilder
    private func navigationButton(_ section: MainSection, shortcut: KeyEquivalent? = nil) -> some View {
        if let shortcut {
            Button(section.title(language: language)) {
                appState.navigate(to: section)
            }
            .keyboardShortcut(shortcut, modifiers: [.command])
        } else {
            Button(section.title(language: language)) {
                appState.navigate(to: section)
            }
        }
    }

    private func t(_ key: String) -> String {
        L10n.text(key, language: language)
    }

    private var appFont: Font {
        let size = max(11, min(18, appState.settingsStore.settings.baseFontSize))
        let fontName = appState.settingsStore.settings.fontName.trimmingCharacters(in: .whitespacesAndNewlines)
        if fontName.isEmpty || fontName == "System" {
            return .system(size: size)
        }
        return .custom(fontName, size: size)
    }

    private var controlSize: ControlSize {
        switch AppInterfaceDensity.normalize(appState.settingsStore.settings.interfaceDensity) {
        case .compact:
            return .small
        case .regular:
            return .regular
        case .spacious:
            return .large
        }
    }

    private var colorScheme: ColorScheme? {
        switch AppAppearanceMode.normalize(appState.settingsStore.settings.appearanceMode) {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
