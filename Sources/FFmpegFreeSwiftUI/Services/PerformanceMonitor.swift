import Foundation

public struct PerformanceSnapshot: Equatable, Sendable {
    public var cpuLoadText: String
    public var memoryText: String
    public var diskText: String
    public var processCountText: String
    public var gpuText: String

    public static let empty = PerformanceSnapshot(
        cpuLoadText: "N/A",
        memoryText: "N/A",
        diskText: "N/A",
        processCountText: "N/A",
        gpuText: "macOS 首版未读取 GPU/显存"
    )
}

public struct PerformanceMonitor: Sendable {
    public init() {}

    public func snapshot() async -> PerformanceSnapshot {
        async let memory = runText(path: "/usr/bin/vm_stat", arguments: [])
        async let processList = runText(path: "/bin/ps", arguments: ["-ax"])
        let memoryText = await memory
            .split(separator: "\n")
            .prefix(4)
            .joined(separator: " | ")
        let processLines = await processList.split(separator: "\n")
        return PerformanceSnapshot(
            cpuLoadText: loadAverage(),
            memoryText: memoryText.isEmpty ? "N/A" : memoryText,
            diskText: diskUsage(),
            processCountText: "\(max(processLines.count - 1, 0))",
            gpuText: "N/A"
        )
    }

    private func loadAverage() -> String {
        var loads = [Double](repeating: 0, count: 3)
        getloadavg(&loads, 3)
        return String(format: "%.2f / %.2f / %.2f", loads[0], loads[1], loads[2])
    }

    private func diskUsage() -> String {
        do {
            let attrs = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            let free = attrs[.systemFreeSize] as? NSNumber
            let size = attrs[.systemSize] as? NSNumber
            guard let free, let size else { return "N/A" }
            let used = size.int64Value - free.int64Value
            let usedGB = Double(used) / 1_073_741_824
            let totalGB = Double(size.int64Value) / 1_073_741_824
            return String(format: "%.1f / %.1f GB", usedGB, totalGB)
        } catch {
            return "N/A"
        }
    }

    private func runText(path: String, arguments: [String]) async -> String {
        await withTaskGroup(of: String.self) { group in
            group.addTask {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: path)
                process.arguments = arguments
                let pipe = Pipe()
                process.standardOutput = pipe
                do {
                    try process.run()
                    process.waitUntilExit()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    return String(data: data, encoding: .utf8) ?? ""
                } catch {
                    return ""
                }
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 800_000_000)
                return ""
            }
            let first = await group.next() ?? ""
            group.cancelAll()
            return first
        }
    }
}
