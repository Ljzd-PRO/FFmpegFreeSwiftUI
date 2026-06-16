import SwiftUI

public struct MuxingView: View {
    @EnvironmentObject private var queueStore: EncodingQueueStore
    @State private var input = ""
    @State private var extraInputs = ""
    @State private var output = ""

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("混流")
                .font(.title2.weight(.semibold))
            TextField("主输入文件", text: $input)
                .textFieldStyle(.roundedBorder)
            TextField("附加输入参数，如 -i subtitle.srt -i audio.m4a", text: $extraInputs)
                .textFieldStyle(.roundedBorder)
            TextField("输出文件", text: $output)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("选择主输入") { openFile { input = $0 } }
                Button("选择输出") { saveFile { output = $0 } }
                Button("加入队列") { addTask() }
                    .disabled(input.isEmpty || output.isEmpty)
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .padding(24)
    }

    private func addTask() {
        let args = "-hide_banner -nostdin -i \(ShellQuoting.quote(input)) \(extraInputs) -c copy \(ShellQuoting.quote(output)) -y"
        queueStore.addCommandTask(arguments: args, displayName: "混流任务", outputPath: output, inputPath: input)
    }
}

public struct MergingView: View {
    @EnvironmentObject private var queueStore: EncodingQueueStore
    @State private var files: [String] = []
    @State private var output = ""

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("合并")
                .font(.title2.weight(.semibold))
            HStack {
                Button("添加片段") { openFiles { files.append(contentsOf: $0) } }
                Button("清空") { files.removeAll() }
                TextField("输出文件", text: $output)
                    .textFieldStyle(.roundedBorder)
                Button("选择输出") { saveFile { output = $0 } }
                Button("加入队列") { addTask() }
                    .disabled(files.isEmpty || output.isEmpty)
            }
            .buttonStyle(.bordered)
            List(files, id: \.self) { path in
                Text(path)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(24)
    }

    private func addTask() {
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent("ffmpeg_concat_demuxer_\(UUID().uuidString).txt")
        let body = files.map { "file '\($0.replacingOccurrences(of: "'", with: "'\\''"))'" }.joined(separator: "\n")
        try? body.write(to: temp, atomically: true, encoding: .utf8)
        let args = "-hide_banner -nostdin -f concat -safe 0 -i \(ShellQuoting.quote(temp.path)) -c copy \(ShellQuoting.quote(output)) -y"
        queueStore.addCommandTask(arguments: args, displayName: "合并任务", outputPath: output)
    }
}

public struct QualityAssessmentView: View {
    @EnvironmentObject private var queueStore: EncodingQueueStore
    @State private var reference = ""
    @State private var distorted = ""
    @State private var metric = "ssim"
    @State private var output = "-"

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("画质评测")
                .font(.title2.weight(.semibold))
            TextField("参考文件", text: $reference)
                .textFieldStyle(.roundedBorder)
            TextField("待评测文件", text: $distorted)
                .textFieldStyle(.roundedBorder)
            Picker("指标", selection: $metric) {
                Text("SSIM").tag("ssim")
                Text("PSNR").tag("psnr")
                Text("VMAF").tag("libvmaf")
            }
            .pickerStyle(.segmented)
            TextField("输出日志文件，留空或 - 表示控制台", text: $output)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("选择参考") { openFile { reference = $0 } }
                Button("选择待评测") { openFile { distorted = $0 } }
                Button("加入队列") { addTask() }
                    .disabled(reference.isEmpty || distorted.isEmpty)
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .padding(24)
    }

    private func addTask() {
        let filter = metric == "libvmaf" ? "libvmaf" : "\(metric)"
        let log = output.isEmpty ? "-" : output
        let args = "-hide_banner -nostdin -i \(ShellQuoting.quote(distorted)) -i \(ShellQuoting.quote(reference)) -lavfi \(ShellQuoting.quote(filter)) -f null \(ShellQuoting.quote(log)) -y"
        queueStore.addCommandTask(arguments: args, displayName: "画质评测任务", outputPath: log, inputPath: distorted)
    }
}

public struct PluginExtensionView: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("插件扩展")
                .font(.title2.weight(.semibold))
            Text("旧版 Windows .3fui.dll 反射插件不兼容 macOS SwiftUI 首版。当前保留页面和内部队列 API，后续可设计 Swift 原生插件方案。")
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private func openFile(_ completion: @escaping (String) -> Void) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.begin { response in
        guard response == .OK, let url = panel.url else { return }
        completion(url.path)
    }
}

private func openFiles(_ completion: @escaping ([String]) -> Void) {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = true
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.begin { response in
        guard response == .OK else { return }
        completion(panel.urls.map(\.path))
    }
}

private func saveFile(_ completion: @escaping (String) -> Void) {
    let panel = NSSavePanel()
    panel.begin { response in
        guard response == .OK, let url = panel.url else { return }
        completion(url.path)
    }
}
