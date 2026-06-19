import Foundation
import Network

@MainActor
public final class RemoteCommandServer: ObservableObject {
    @Published public var isRunning = false
    @Published public var lastMessage = ""

    private var listener: NWListener?
    private weak var queueStore: EncodingQueueStore?
    private var activePort = ""

    public init(queueStore: EncodingQueueStore) {
        self.queueStore = queueStore
    }

    public func update(enabled: Bool, port: String) {
        if enabled {
            let cleanPort = normalizedPort(port)
            if isRunning, activePort == cleanPort {
                return
            }
            start(port: port)
        } else {
            guard listener != nil || isRunning else { return }
            stop()
        }
    }

    public func start(port: String) {
        stop()
        let cleanPort = normalizedPort(port)
        guard let value = UInt16(cleanPort), let nwPort = NWEndpoint.Port(rawValue: value) else {
            lastMessage = "端口无效"
            return
        }
        do {
            let listener = try NWListener(using: .udp, on: nwPort)
            listener.newConnectionHandler = { [weak self] connection in
                connection.start(queue: .global(qos: .utility))
                self?.receive(on: connection)
            }
            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    switch state {
                    case .ready:
                        self?.isRunning = true
                        self?.activePort = cleanPort
                        self?.lastMessage = "UDP 监听中: \(cleanPort)"
                    case .failed(let error):
                        self?.isRunning = false
                        self?.lastMessage = "监听失败: \(error.localizedDescription)"
                    case .cancelled:
                        self?.isRunning = false
                    default:
                        break
                    }
                }
            }
            listener.start(queue: .global(qos: .utility))
            self.listener = listener
        } catch {
            lastMessage = "监听失败: \(error.localizedDescription)"
        }
    }

    public func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
        activePort = ""
    }

    nonisolated private func receive(on connection: NWConnection) {
        connection.receiveMessage { [weak self] data, _, _, _ in
            guard let data, let text = String(data: data, encoding: .utf8) else {
                connection.cancel()
                return
            }
            Task { @MainActor [weak self] in
                self?.handleCommand(text)
            }
            connection.cancel()
        }
    }

    private func handleCommand(_ text: String) {
        lastMessage = text
        let args = ShellQuoting.splitArguments(text)
        parse(args: args)
    }

    public func parse(args: [String]) {
        guard let queueStore else { return }
        if let ffmpegIndex = args.firstIndex(of: "-ffmpeg") {
            let ffmpegArgs = ShellQuoting.joinArguments(Array(args.dropFirst(ffmpegIndex + 1)))
            queueStore.addCommandTask(arguments: ffmpegArgs, displayName: "远程命令行任务")
            return
        }
        var input = ""
        var preset = ""
        var index = 0
        while index < args.count {
            let item = args[index]
            if item == "-i", index + 1 < args.count {
                input = args[index + 1]
                index += 2
                continue
            }
            if item == "-3fui_file", index + 1 < args.count {
                preset = args[index + 1]
                index += 2
                continue
            }
            index += 1
        }
        if !input.isEmpty, !preset.isEmpty {
            queueStore.addPresetFileTask(
                presetPath: preset,
                displayName: URL(fileURLWithPath: input).lastPathComponent,
                inputPath: input
            )
        }
    }

    public static func normalizedPort(_ port: String) -> String {
        port == "10590" || port.isEmpty ? "10591" : port
    }

    private func normalizedPort(_ port: String) -> String {
        Self.normalizedPort(port)
    }
}
