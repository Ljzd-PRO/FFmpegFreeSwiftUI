import SwiftUI

public struct QualityAssessmentView: View {
    @EnvironmentObject private var qualityStore: QualityAssessmentStore
    @State private var referenceFile = ""
    @State private var distortedFiles: [String] = []
    @State private var selectedDistorted = Set<String>()
    @State private var selectedMetrics = Set<QualityMetric>([.psnr, .ssim])
    @State private var configuration = QualityAssessmentConfiguration()
    @State private var selectedBottomTab = BottomTab.queue

    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    adaptiveTopLayout(width: proxy.size.width - 48)
                    bottomPanel
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { qualityStore.refreshFilterAvailability() }
    }

    @ViewBuilder
    private func adaptiveTopLayout(width: CGFloat) -> some View {
        if width >= 980 {
            HStack(alignment: .top, spacing: 14) {
                fileColumn
                    .frame(minWidth: 0, maxWidth: .infinity)
                configurationColumn
                    .frame(width: min(300, max(260, width * 0.25)))
                resultsColumn
                    .frame(minWidth: 260, maxWidth: min(360, width * 0.28))
            }
        } else if width >= 680 {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    fileColumn
                        .frame(minWidth: 0, maxWidth: .infinity)
                    configurationColumn
                        .frame(width: min(300, max(250, width * 0.36)))
                }
                resultsColumn
            }
        } else {
            VStack(alignment: .leading, spacing: 14) {
                fileColumn
                configurationColumn
                resultsColumn
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            ToolBanner(text: "视频质量评测并不能代表绝对表现，其会受到各种因素的影响，请以人眼视觉为准")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Button("重置页面") {
                        referenceFile = ""
                        distortedFiles.removeAll()
                        selectedDistorted.removeAll()
                        configuration = QualityAssessmentConfiguration()
                        qualityStore.resetPageState()
                    }
                    Button("全新开始评测") {
                        enqueue(resetQueue: true, selectedOnly: false)
                    }
                    Button("从选择处开始") {
                        enqueue(resetQueue: false, selectedOnly: true)
                    }
                    Button("停止") { qualityStore.stop() }
                        .disabled(!qualityStore.isRunning)
                    if !qualityStore.statusMessage.isEmpty {
                        StatusPill(text: qualityStore.statusMessage, color: .green)
                    }
                }
                .buttonStyle(.bordered)
                .fixedSize(horizontal: true, vertical: false)
            }
        }
    }

    private var fileColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            GroupBox("原视频") {
                HStack {
                    TextField("选择原视频文件", text: $referenceFile)
                        .textFieldStyle(.roundedBorder)
                    Button("选择") { ToolFilePanels.openFile { referenceFile = $0 } }
                }
                .padding(8)
            }

            GroupBox("编码后的文件") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button("添加编码后的文件") { ToolFilePanels.openFiles(addDistortedFiles) }
                        Button("移除") { removeSelectedDistorted() }.disabled(selectedDistorted.isEmpty)
                        Spacer()
                    }
                    .buttonStyle(.bordered)
                    List(selection: $selectedDistorted) {
                        ForEach(distortedFiles, id: \.self) { file in
                            Text(file)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    .frame(minHeight: 200, maxHeight: 300)
                    .acceptsFileDrops(addDistortedFiles)
                }
                .padding(8)
            }

            GroupBox("指标") {
                VStack(alignment: .leading, spacing: 8) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), alignment: .leading)], alignment: .leading, spacing: 8) {
                        ForEach(QualityMetric.allCases) { metric in
                            Toggle(metric.rawValue, isOn: metricBinding(metric))
                                .disabled(!isMetricEnabled(metric))
                                .help(metricHelp(metric))
                        }
                    }
                    Text("PSNR/SSIM/XPSNR 需要两路视频尺寸、帧率和像素格式可比较；VMAF 需要本机 ffmpeg 启用 libvmaf。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
            }
        }
    }

    private var configurationColumn: some View {
        GroupBox("通用配置 / VMAF 配置") {
            VStack(alignment: .leading, spacing: 12) {
                configField("评测时长", placeholder: "例如 00:00:10 或 10", text: $configuration.duration)
                configField("从指定位置开始", placeholder: "例如 00:01:00", text: $configuration.startTime)
                HStack {
                    configField("输出目录", placeholder: "留空则输出到原视频目录", text: $configuration.outputDirectory)
                    Button("浏览") { ToolFilePanels.openDirectory { configuration.outputDirectory = $0 } }
                }
                configField("VMAF 模型", placeholder: "留空使用 ffmpeg 默认模型", text: $configuration.vmafModel)
                configField("VMAF 统计方式", placeholder: "mean / harmonic_mean / min", text: $configuration.vmafPool)
                configField("抽样", placeholder: "每隔 N 帧评测，留空为全量", text: $configuration.sampleInterval)
                Spacer(minLength: 0)
            }
            .padding(8)
        }
    }

    private var resultsColumn: some View {
        GroupBox("最近结果") {
            List(qualityStore.results.prefix(8)) { result in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(result.metric.rawValue)
                            .font(.headline)
                        Spacer()
                        Text(result.score)
                            .font(.system(.body, design: .monospaced).weight(.semibold))
                    }
                    Text(URL(fileURLWithPath: result.distortedFile).lastPathComponent)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text("最低 \(result.minimum)")
                        Text(FileSizeFormatting.durationText(result.elapsedSeconds))
                        Spacer()
                        Button("复制") { qualityStore.copyResult(result) }
                        Button("日志") { qualityStore.revealLog(result) }
                    }
                    .font(.caption)
                }
                .padding(.vertical, 4)
            }
            .frame(minHeight: 220, maxHeight: 340)
        }
    }

    private var bottomPanel: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Picker("", selection: $selectedBottomTab) {
                    Text("测评队列").tag(BottomTab.queue)
                    Text("结果历史").tag(BottomTab.history)
                    Text("实时日志").tag(BottomTab.log)
                }
                .pickerStyle(.segmented)
                switch selectedBottomTab {
                case .queue:
                    queueList
                case .history:
                    historyList
                case .log:
                    logView
                }
            }
            .padding(8)
        }
    }

    private var queueList: some View {
        Table(qualityStore.tasks, selection: $qualityStore.selectedTaskID) {
            TableColumn("状态") { task in Text(task.status.rawValue) }.width(80)
            TableColumn("文件") { task in
                Text(URL(fileURLWithPath: task.distortedFile).lastPathComponent)
                    .lineLimit(1)
            }
            TableColumn("当前指标") { task in Text(task.currentMetric?.rawValue ?? "-") }.width(90)
            TableColumn("结果") { task in Text(task.results.map { "\($0.metric.rawValue): \($0.score)" }.joined(separator: "  ")) }
        }
        .frame(minHeight: 170, maxHeight: 260)
    }

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button("清空历史") { qualityStore.clearHistory() }
                    .buttonStyle(.bordered)
                Spacer()
            }
            Table(qualityStore.results) {
                TableColumn("时间") { result in Text(result.completedAt.formatted(date: .numeric, time: .shortened)) }.width(150)
                TableColumn("指标") { result in Text(result.metric.rawValue) }.width(70)
                TableColumn("分数") { result in Text(result.score) }.width(80)
                TableColumn("文件") { result in Text(URL(fileURLWithPath: result.distortedFile).lastPathComponent) }
                TableColumn("日志") { result in Text(result.logPath).lineLimit(1) }
            }
            .frame(minHeight: 170, maxHeight: 260)
        }
    }

    private var logView: some View {
        ScrollView {
            Text(qualityStore.selectedTask?.realtimeOutput ?? "暂无实时输出")
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
        }
        .frame(minHeight: 170, maxHeight: 260)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func configField(_ title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func metricBinding(_ metric: QualityMetric) -> Binding<Bool> {
        Binding(
            get: { selectedMetrics.contains(metric) },
            set: { isOn in
                if isOn {
                    selectedMetrics.insert(metric)
                } else {
                    selectedMetrics.remove(metric)
                }
            }
        )
    }

    private func isMetricEnabled(_ metric: QualityMetric) -> Bool {
        qualityStore.filterAvailability.available.isEmpty || qualityStore.filterAvailability.isAvailable(metric)
    }

    private func metricHelp(_ metric: QualityMetric) -> String {
        qualityStore.filterAvailability.unavailableReasons[metric] ?? "\(metric.rawValue) 可用"
    }

    private func addDistortedFiles(_ paths: [String]) {
        for path in paths where !distortedFiles.contains(path) {
            distortedFiles.append(path)
        }
    }

    private func removeSelectedDistorted() {
        distortedFiles.removeAll { selectedDistorted.contains($0) }
        selectedDistorted.removeAll()
    }

    private func enqueue(resetQueue: Bool, selectedOnly: Bool) {
        let files = selectedOnly && !selectedDistorted.isEmpty ? Array(selectedDistorted) : distortedFiles
        qualityStore.enqueue(
            referenceFile: referenceFile,
            distortedFiles: files,
            metrics: Array(selectedMetrics),
            configuration: configuration,
            resetQueue: resetQueue
        )
    }
}

private enum BottomTab {
    case queue
    case history
    case log
}
