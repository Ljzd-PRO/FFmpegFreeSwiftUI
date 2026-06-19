import Foundation
import FFmpegFreeSwiftUI

public func makeFeatureRuntimeTests() -> [TestCase] {
    [
        TestCase("Feature runtime queue", "Queue completes tiny transcode", requiresFFmpeg: true) { context in
            let media = try TestMediaFactory.make(context: context)
            guard let ffmpegPath = context.ffmpegPath else { throw TestSkip("ffmpeg not found") }
            let output = context.tempRoot.appendingPathComponent("queue-runtime.mp4")
            final class StoreBox: @unchecked Sendable { var store: EncodingQueueStore? }
            let box = StoreBox()

            try await runOnMainActor {
                let settingsStore = SettingsStore(url: context.tempRoot.appendingPathComponent("settings.json"))
                settingsStore.settings.ffmpegExecutableOverride = ffmpegPath
                settingsStore.settings.maxConcurrentTasks = 1
                let store = EncodingQueueStore(settingsStore: settingsStore)
                box.store = store
                store.addCommandTask(
                    arguments: ShellQuoting.joinArguments([
                        "-hide_banner", "-nostdin",
                        "-i", media.sourceMP4.path,
                        "-c:v", "mpeg4",
                        "-q:v", "8",
                        "-c:a", "aac",
                        "-b:a", "64k",
                        output.path,
                        "-y"
                    ]),
                    displayName: "queue runtime",
                    outputPath: output.path,
                    inputPath: media.sourceMP4.path
                )
                store.startSelected()
                try expectEqual(store.selectedTask?.status, .running, "task starts running")
            }

            try await waitUntil(timeout: 20) {
                await MainActor.run {
                    box.store?.selectedTask?.status == .completed
                }
            }

            try await runOnMainActor {
                let task = try requireRuntimeTask(box.store?.selectedTask, "selected task")
                try expectEqual(task.status, .completed, "completed status")
                try expectEqual(task.progress.percent, 1, "completion percent")
                try expect(FileManager.default.fileExists(atPath: output.path), "output should exist")
            }
        },
        TestCase("Feature runtime tools", "FFprobe reads generated media", requiresFFmpeg: true) { context in
            let media = try TestMediaFactory.make(context: context)
            guard let ffmpegPath = context.ffmpegPath else { throw TestSkip("ffmpeg not found") }
            var settings = AppSettings()
            settings.ffmpegExecutableOverride = ffmpegPath
            let output = try await FFprobeService(locator: FFmpegLocator(settings: settings), settings: settings).probe(file: media.sourceMP4.path)
            try expectContains(output, "Input #0", "ffprobe input")
            try expect(output.contains("Video:") || output.contains("Stream #0:0"), "ffprobe should show video stream")
        },
        TestCase("Feature runtime quality", "Quality store runs PSNR task", requiresFFmpeg: true) { context in
            let media = try TestMediaFactory.make(context: context)
            guard let ffmpegPath = context.ffmpegPath else { throw TestSkip("ffmpeg not found") }
            let distorted = context.tempRoot.appendingPathComponent("feature-quality-distorted.mp4")
            try runFFmpegForFeature(
                ffmpegPath: ffmpegPath,
                arguments: [
                    "-hide_banner", "-i", media.sourceMP4.path,
                    "-vf", "scale=128:72,format=yuv420p",
                    "-c:v", "mpeg4", "-q:v", "20", "-an",
                    distorted.path, "-y"
                ],
                output: distorted
            )
            guard try ffmpegFilterExistsForFeature(context: context, filter: "psnr") else {
                throw TestSkip("psnr filter not available")
            }

            final class StoreBox: @unchecked Sendable { var store: QualityAssessmentStore? }
            let box = StoreBox()
            try await runOnMainActor {
                let settingsStore = SettingsStore(url: context.tempRoot.appendingPathComponent("settings.json"))
                settingsStore.settings.ffmpegExecutableOverride = ffmpegPath
                let store = QualityAssessmentStore(
                    settingsStore: settingsStore,
                    historyURL: context.tempRoot.appendingPathComponent("quality-history.json")
                )
                store.filterAvailability = QualityFilterAvailability(available: [.psnr], unavailableReasons: [:])
                box.store = store
                store.enqueue(
                    referenceFile: media.sourceMP4.path,
                    distortedFiles: [distorted.path],
                    metrics: [.psnr],
                    configuration: QualityAssessmentConfiguration(duration: "0.5", outputDirectory: context.tempRoot.path),
                    resetQueue: true
                )
            }

            try await waitUntil(timeout: 30) {
                await MainActor.run {
                    box.store?.tasks.first?.status == .completed
                }
            }

            try await runOnMainActor {
                let store = try requireRuntimeTask(box.store, "quality store")
                let task = try requireRuntimeTask(store.tasks.first, "quality task")
                try expectEqual(task.status, .completed, "quality completed")
                try expectEqual(task.results.count, 1, "one quality result")
                try expect(task.results[0].score != "N/A", "PSNR should produce score")
                try expectEqual(store.results.count, 1, "history result")
            }
        },
        TestCase("Feature runtime mux merge", "Muxing command produces output", requiresFFmpeg: true) { context in
            let media = try TestMediaFactory.make(context: context)
            guard let ffmpegPath = context.ffmpegPath else { throw TestSkip("ffmpeg not found") }
            let output = context.tempRoot.appendingPathComponent("feature-mux.mkv")
            let command = MuxingCommandBuilder().build(
                inputs: [
                    MuxingInput(path: media.sourceMP4.path, videoStreams: "0", audioStreams: "0", usesChapters: true, usesMetadata: true),
                    MuxingInput(path: media.subtitleSRT.path, subtitleStreams: "0")
                ],
                output: output.path
            )
            try runFFmpegForFeature(ffmpegPath: ffmpegPath, arguments: ShellQuoting.splitArguments(command), output: output)
        },
        TestCase("Feature runtime mux merge", "Merging concat command produces output", requiresFFmpeg: true) { context in
            let media = try TestMediaFactory.make(context: context)
            guard let ffmpegPath = context.ffmpegPath else { throw TestSkip("ffmpeg not found") }
            let first = context.tempRoot.appendingPathComponent("concat-a.mp4")
            let second = context.tempRoot.appendingPathComponent("concat-b.mp4")
            for output in [first, second] {
                try runFFmpegForFeature(
                    ffmpegPath: ffmpegPath,
                    arguments: [
                        "-hide_banner", "-i", media.sourceMP4.path,
                        "-t", "0.4",
                        "-c:v", "mpeg4",
                        "-q:v", "8",
                        "-c:a", "aac",
                        "-b:a", "64k",
                        output.path,
                        "-y"
                    ],
                    output: output
                )
            }
            let builder = MergingCommandBuilder()
            let concat = try builder.writeConcatFile(files: [first.path, second.path], directory: context.tempRoot)
            let output = context.tempRoot.appendingPathComponent("feature-merged.mp4")
            try runFFmpegForFeature(ffmpegPath: ffmpegPath, arguments: ShellQuoting.splitArguments(builder.build(concatFile: concat.path, output: output.path)), output: output)
        },
        TestCase("Feature runtime queue", "Stop marks running lavfi task stopped", requiresFFmpeg: true) { context in
            guard let ffmpegPath = context.ffmpegPath else { throw TestSkip("ffmpeg not found") }
            final class StoreBox: @unchecked Sendable { var store: EncodingQueueStore? }
            let box = StoreBox()
            try await runOnMainActor {
                let settingsStore = SettingsStore(url: context.tempRoot.appendingPathComponent("settings.json"))
                settingsStore.settings.ffmpegExecutableOverride = ffmpegPath
                let store = EncodingQueueStore(settingsStore: settingsStore)
                box.store = store
                store.addCommandTask(
                    arguments: "-hide_banner -nostdin -re -f lavfi -i testsrc2=size=64x64:rate=10:duration=10 -f null -",
                    displayName: "stoppable"
                )
                store.startSelected()
            }
            try await Task.sleep(nanoseconds: 300_000_000)
            try await runOnMainActor {
                let store = try requireRuntimeTask(box.store, "queue store")
                let task = try requireRuntimeTask(store.selectedTask, "selected task")
                store.stop(task)
            }
            try await waitUntil(timeout: 5) {
                await MainActor.run {
                    box.store?.selectedTask?.status == .stopped
                }
            }
        }
    ]
}

private func requireRuntimeTask<T>(_ value: T?, _ message: String) throws -> T {
    guard let value else {
        throw TestFailure(message)
    }
    return value
}

private func runFFmpegForFeature(ffmpegPath: String, arguments: [String], output: URL) throws {
    let result = try runProcess(ffmpegPath, arguments: arguments, timeout: 30)
    guard result.status == 0 else {
        throw TestFailure("ffmpeg failed with status \(result.status)\n\(result.output)")
    }
    try expect(FileManager.default.fileExists(atPath: output.path), "runtime output should exist: \(output.path)")
    let attributes = try FileManager.default.attributesOfItem(atPath: output.path)
    try expect(((attributes[.size] as? NSNumber)?.intValue ?? 0) > 0, "runtime output should not be empty")
}

private func ffmpegFilterExistsForFeature(context: TestContext, filter: String) throws -> Bool {
    guard let ffmpegPath = context.ffmpegPath else { return false }
    let result = try runProcess(ffmpegPath, arguments: ["-hide_banner", "-filters"], timeout: 10)
    guard result.status == 0 else { return false }
    return result.output.split(whereSeparator: \.isNewline).contains { line in
        let parts = line.split(separator: " ").map(String.init)
        return parts.contains(filter)
    }
}
