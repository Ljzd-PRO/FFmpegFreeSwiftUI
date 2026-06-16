import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settingsStore: SettingsStore

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("设置")
                    .font(.title2.weight(.semibold))

                settingsSection("性能调度") {
                    Stepper(value: $settingsStore.settings.maxConcurrentTasks, in: 1...10) {
                        Text("自动同时运行任务数量: \(settingsStore.settings.maxConcurrentTasks)")
                    }
                    HStack {
                        Text("编码队列刷新速度")
                        Slider(value: $settingsStore.settings.queueRefreshInterval, in: 0.2...2.0)
                        Text(String(format: "%.1fs", settingsStore.settings.queueRefreshInterval))
                    }
                    TextField("指定处理器核心（保留设置，macOS 首版不绑定 affinity）", text: $settingsStore.settings.selectedProcessorCores)
                }

                settingsSection("功能设定") {
                    Toggle("自动开始任务", isOn: $settingsStore.settings.autoStartTasks)
                    Toggle("启用提示音", isOn: $settingsStore.settings.soundEnabled)
                    Toggle("自动重置参数面板到第一个页面", isOn: $settingsStore.settings.resetParameterPanelOnStart)
                    Toggle("任务名称混淆", isOn: $settingsStore.settings.obfuscateTaskName)
                    Stepper(value: $settingsStore.settings.deleteFailedOutputPolicy, in: 0...2) {
                        Text("任务失败删除输出文件策略: \(settingsStore.settings.deleteFailedOutputPolicy)")
                    }
                    TextField("工作目录", text: $settingsStore.settings.workingDirectory)
                }

                settingsSection("FFmpeg 路径") {
                    TextField("替代 ffmpeg 文件名", text: $settingsStore.settings.ffmpegExecutableOverride)
                    TextField("替代 ffprobe 文件名", text: $settingsStore.settings.ffprobeExecutableOverride)
                    TextField("替代 ffplay 文件名", text: $settingsStore.settings.ffplayExecutableOverride)
                    TextField("覆盖参数传递，使用 <args>", text: $settingsStore.settings.argumentPassthroughTemplate)
                }

                settingsSection("远程调用") {
                    Toggle("启用 UDP 监听", isOn: $settingsStore.settings.remoteCallEnabled)
                    TextField("端口", text: $settingsStore.settings.remotePort)
                    Button("应用远程调用设置") {
                        appState.remoteServer.update(enabled: settingsStore.settings.remoteCallEnabled, port: settingsStore.settings.remotePort)
                    }
                    Text(appState.remoteServer.lastMessage)
                        .foregroundStyle(.secondary)
                }

                settingsSection("界面显示") {
                    TextField("全局字体", text: $settingsStore.settings.fontName)
                    Picker("语言", selection: $settingsStore.settings.language) {
                        Text("中文").tag("zh")
                        Text("English").tag("en")
                    }
                }
            }
            .padding(24)
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content()
        }
        .frame(maxWidth: 760, alignment: .leading)
    }
}
