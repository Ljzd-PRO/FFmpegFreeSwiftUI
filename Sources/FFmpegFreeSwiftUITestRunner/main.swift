import Foundation
import FFmpegFreeSwiftUITestSupport

let configuration: TestConfiguration
do {
    configuration = try TestConfiguration.parse(arguments: Array(CommandLine.arguments.dropFirst()))
} catch {
    print("FAIL Argument parsing: \(error)")
    TestConfiguration.printUsage()
    exit(1)
}

let commandTests = makeCommandOnlyTests()
let runtimeTests = makeRuntimeTests()

let selectedTests: [TestCase]
switch configuration.mode {
case .commandOnly:
    selectedTests = commandTests
case .withFFmpeg:
    selectedTests = runtimeTests
case .all:
    selectedTests = commandTests + runtimeTests
}

if configuration.listOnly {
    for test in selectedTests {
        let marker = test.requiresFFmpeg ? " [ffmpeg]" : ""
        print("\(test.group) / \(test.name)\(marker)")
    }
    exit(0)
}

let ffmpegPath = locateFFmpeg(configuration: configuration)
if configuration.requireFFmpeg, configuration.mode != .commandOnly, ffmpegPath == nil {
    print("FAIL FFmpeg required but not found or not executable")
    exit(1)
}

let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent("FFmpegFreeSwiftUITests-\(UUID().uuidString)", isDirectory: true)

do {
    try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
} catch {
    print("FAIL Temp directory: \(error)")
    exit(1)
}

let context = TestContext(configuration: configuration, ffmpegPath: ffmpegPath, tempRoot: tempRoot)
var failures: [String] = []
var passed = 0
var skipped = 0

for test in selectedTests {
    let label = "\(test.group) / \(test.name)"
    do {
        if test.requiresFFmpeg, ffmpegPath == nil {
            throw TestSkip("ffmpeg not found")
        }
        try test.body(context)
        passed += 1
        print("PASS \(label)")
    } catch let skip as TestSkip {
        skipped += 1
        print("SKIP \(label): \(skip.description)")
    } catch {
        failures.append("FAIL \(label): \(error)")
    }
}

if failures.isEmpty && !configuration.keepTemp {
    try? FileManager.default.removeItem(at: tempRoot)
} else if configuration.keepTemp || !failures.isEmpty {
    print("Temp files: \(tempRoot.path)")
}

if failures.isEmpty {
    let suffix = skipped > 0 ? ", \(skipped) skipped" : ""
    print("All \(passed) selected tests passed\(suffix)")
} else {
    print(failures.joined(separator: "\n"))
    exit(1)
}
