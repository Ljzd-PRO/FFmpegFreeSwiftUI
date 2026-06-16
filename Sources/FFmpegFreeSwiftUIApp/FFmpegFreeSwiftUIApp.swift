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
                .frame(minWidth: 1200, minHeight: 700)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandMenu("编码队列") {
                Button("添加文件...") {
                    appState.presentOpenPanelForQueue()
                }
                .keyboardShortcut("o", modifiers: [.command])
                Button("开始未处理任务") {
                    appState.queueStore.startPending()
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }
    }
}
