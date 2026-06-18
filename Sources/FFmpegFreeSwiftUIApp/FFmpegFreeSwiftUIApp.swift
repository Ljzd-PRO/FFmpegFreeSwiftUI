import SwiftUI
#if !XCODE_APP
import FFmpegFreeSwiftUI
#endif

@main
struct FFmpegFreeSwiftUIExecutableApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environmentObject(appState)
                .environmentObject(appState.settingsStore)
                .environmentObject(appState.presetStore)
                .environmentObject(appState.queueStore)
                .environmentObject(appState.qualityStore)
                .frame(minWidth: 1200, minHeight: 700)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .appSettings) {
                Button("设置...") {
                    appState.navigate(to: .settings)
                }
                .keyboardShortcut(",", modifiers: [.command])
            }
            CommandMenu("文件") {
                Button("添加文件到编码队列...") {
                    appState.presentOpenPanelForQueue()
                }
                .keyboardShortcut("o", modifiers: [.command])
                Divider()
                Button("导入预设...") {
                    appState.presentPresetImportPanel()
                }
                .keyboardShortcut("o", modifiers: [.command, .option])
                Button("导出当前预设...") {
                    appState.presentPresetExportPanel()
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
            }
            CommandMenu("导航") {
                Button("3FUI") { appState.navigate(to: .start) }
                    .keyboardShortcut("1", modifiers: [.command])
                Button("编码队列") { appState.navigate(to: .encodeQueue) }
                    .keyboardShortcut("2", modifiers: [.command])
                Button("准备文件") { appState.navigate(to: .prepareFiles) }
                    .keyboardShortcut("3", modifiers: [.command])
                Button("参数面板") { appState.navigate(to: .parameterPanel) }
                    .keyboardShortcut("4", modifiers: [.command])
                Button("媒体信息") { appState.navigate(to: .mediaInfo) }
                    .keyboardShortcut("5", modifiers: [.command])
                Button("播放器") { appState.navigate(to: .player) }
                    .keyboardShortcut("6", modifiers: [.command])
                Button("画质评测") { appState.navigate(to: .quality) }
                    .keyboardShortcut("7", modifiers: [.command])
                Button("混流") { appState.navigate(to: .muxing) }
                    .keyboardShortcut("8", modifiers: [.command])
                Button("合并") { appState.navigate(to: .merging) }
                    .keyboardShortcut("9", modifiers: [.command])
                Button("性能监控") { appState.navigate(to: .performance) }
                    .keyboardShortcut("0", modifiers: [.command])
                Divider()
                Button("插件扩展") { appState.navigate(to: .plugins) }
                Button("设置") { appState.navigate(to: .settings) }
                Button("支持者") { appState.navigate(to: .supporters) }
            }
            CommandMenu("编码队列") {
                Button("添加文件...") {
                    appState.presentOpenPanelForQueue()
                }
                Button("开始未处理任务") {
                    appState.queueStore.startPending()
                }
                .keyboardShortcut("r", modifiers: [.command])
                Button("开始选中任务") {
                    appState.queueStore.startSelected()
                }
                .disabled(appState.queueStore.selectedTask == nil)
                Button("暂停选中任务") {
                    appState.queueStore.pauseSelected()
                }
                .disabled(appState.queueStore.selectedTask?.status != .running)
                Button("恢复选中任务") {
                    appState.queueStore.resumeSelected()
                }
                .disabled(appState.queueStore.selectedTask?.status != .paused)
                Button("停止选中任务") {
                    appState.queueStore.stopSelected()
                }
                .disabled(appState.queueStore.selectedTask == nil)
                Divider()
                Button("移除选中任务") {
                    appState.queueStore.removeSelected()
                }
                .disabled(appState.queueStore.selectedTask == nil)
                Button("重置选中任务") {
                    appState.queueStore.resetSelected()
                }
                .disabled(appState.queueStore.selectedTask == nil)
                Divider()
                Button("复制任务命令行") {
                    appState.queueStore.copySelectedCommandLine()
                }
                .disabled(appState.queueStore.selectedTask == nil)
                Button("在 Finder 中显示输出") {
                    appState.queueStore.revealSelectedOutput()
                }
                .disabled(appState.queueStore.selectedTask == nil)
            }
            CommandMenu("参数/预设") {
                Button("重置当前参数") {
                    appState.presetStore.reset()
                    appState.navigate(to: .parameterPanel)
                }
                Divider()
                Button("导入预设...") {
                    appState.presentPresetImportPanel()
                    appState.navigate(to: .parameterPanel)
                }
                .keyboardShortcut("o", modifiers: [.command, .option])
                Button("导出当前预设...") {
                    appState.presentPresetExportPanel()
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
                Divider()
                Button("参数面板覆盖到选中任务") {
                    appState.queueStore.overwriteSelectedTaskPreset(with: appState.presetStore.current)
                    appState.navigate(to: .encodeQueue)
                }
                .disabled(appState.queueStore.selectedTask == nil)
                Button("选中任务参数覆盖到参数面板") {
                    if let selectedTask = appState.queueStore.selectedTask {
                        appState.presetStore.loadFromTask(selectedTask)
                        appState.navigate(to: .parameterPanel)
                    }
                }
                .disabled(appState.queueStore.selectedTask?.preset == nil)
            }
            CommandMenu("工具") {
                Button("媒体信息") { appState.navigate(to: .mediaInfo) }
                Button("播放器") { appState.navigate(to: .player) }
                Button("画质评测") { appState.navigate(to: .quality) }
                Divider()
                Button("混流") { appState.navigate(to: .muxing) }
                Button("合并") { appState.navigate(to: .merging) }
                Divider()
                Button("性能监控") { appState.navigate(to: .performance) }
            }
            CommandMenu("帮助") {
                Button("插件扩展") { appState.navigate(to: .plugins) }
                Button("支持者") { appState.navigate(to: .supporters) }
            }
        }
    }
}
