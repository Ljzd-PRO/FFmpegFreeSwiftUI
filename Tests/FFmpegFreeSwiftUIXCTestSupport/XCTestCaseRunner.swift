import XCTest

final class XCTestCaseRunner {
    private let tests: [TestCase]
    private let configuration: TestConfiguration

    init(tests: [TestCase], defaultMode: TestMode) {
        self.tests = tests
        do {
            configuration = try TestConfiguration.environmentDefaults(defaultMode: defaultMode)
        } catch {
            configuration = TestConfiguration(mode: defaultMode)
        }
    }

    func run(_ index: Int, in testCase: XCTestCase) throws {
        let sharedTest = tests[index]
        guard isTestSelected(sharedTest, mode: configuration.mode) else {
            throw XCTSkip("disabled by \(TestConfiguration.modeEnvironmentKey)=\(configuration.mode.rawValue)")
        }

        let ffmpegPath = locateFFmpeg(configuration: configuration)
        if sharedTest.requiresFFmpeg, ffmpegPath == nil {
            throw XCTSkip("ffmpeg not found")
        }

        let testConfiguration = TestConfiguration(
            mode: sharedTest.requiresFFmpeg ? .withFFmpeg : .commandOnly,
            ffmpegPath: ffmpegPath,
            requireFFmpeg: configuration.requireFFmpeg,
            keepTemp: configuration.keepTemp
        )
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("FFmpegFreeSwiftUIXCTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer {
            if !configuration.keepTemp {
                try? FileManager.default.removeItem(at: tempRoot)
            }
        }

        let context = TestContext(configuration: testConfiguration, ffmpegPath: ffmpegPath, tempRoot: tempRoot)
        do {
            try sharedTest.body(context)
        } catch let skip as TestSkip {
            throw XCTSkip(skip.description)
        } catch {
            XCTFail("\(sharedTest.group) / \(sharedTest.name): \(error)", file: #filePath, line: #line)
        }
    }
}
