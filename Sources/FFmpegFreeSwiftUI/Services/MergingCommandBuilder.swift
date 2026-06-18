import Foundation

public struct MergingCommandBuilder: Sendable {
    public init() {}

    public func concatFileBody(files: [String]) -> String {
        files
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { "file '\(escapeConcatPath($0))'" }
            .joined(separator: "\n")
    }

    public func writeConcatFile(files: [String], directory: URL = FileManager.default.temporaryDirectory) throws -> URL {
        let url = directory.appendingPathComponent("ffmpeg_concat_demuxer_\(UUID().uuidString).txt")
        try concatFileBody(files: files).write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    public func build(concatFile: String, output: String) -> String {
        ShellQuoting.joinArguments([
            "-hide_banner", "-nostdin",
            "-f", "concat",
            "-safe", "0",
            "-i", concatFile,
            "-c", "copy",
            output,
            "-y"
        ])
    }

    private func escapeConcatPath(_ path: String) -> String {
        path.replacingOccurrences(of: "'", with: "'\\''")
    }
}
