import Foundation

public struct MuxingInput: Identifiable, Equatable, Sendable {
    public var id: UUID
    public var path: String
    public var videoStreams: String
    public var audioStreams: String
    public var subtitleStreams: String
    public var usesChapters: Bool
    public var usesMetadata: Bool

    public init(
        id: UUID = UUID(),
        path: String,
        videoStreams: String = "",
        audioStreams: String = "",
        subtitleStreams: String = "",
        usesChapters: Bool = false,
        usesMetadata: Bool = false
    ) {
        self.id = id
        self.path = path
        self.videoStreams = videoStreams
        self.audioStreams = audioStreams
        self.subtitleStreams = subtitleStreams
        self.usesChapters = usesChapters
        self.usesMetadata = usesMetadata
    }
}

public struct MuxingCommandBuilder: Sendable {
    public init() {}

    public func build(inputs: [MuxingInput], output: String) -> String {
        var args: [String] = ["-hide_banner", "-nostdin"]
        for input in inputs {
            guard !input.path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            args += ["-i", input.path]
        }

        for (inputIndex, input) in inputs.enumerated() {
            appendMaps(streams: input.videoStreams, prefix: "\(inputIndex):v", codec: "v", to: &args)
            appendMaps(streams: input.audioStreams, prefix: "\(inputIndex):a", codec: "a", to: &args)
            appendMaps(streams: input.subtitleStreams, prefix: "\(inputIndex):s", codec: "s", to: &args)
            if input.usesChapters {
                args += ["-map_chapters", "\(inputIndex)"]
            }
            if input.usesMetadata {
                args += ["-map_metadata", "\(inputIndex)"]
            }
        }

        if !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            args.append(output)
        }
        args.append("-y")
        return ShellQuoting.joinArguments(args)
    }

    private func appendMaps(streams: String, prefix: String, codec: String, to args: inout [String]) {
        for stream in streamIndexes(from: streams) {
            args += ["-map", "\(prefix):\(stream)", "-c:\(codec)", "copy"]
        }
    }

    private func streamIndexes(from text: String) -> [String] {
        text.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
