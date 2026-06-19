import XCTest

final class FeatureRuntimeXCTests: XCTestCase {
    private let runner = XCTestCaseRunner(tests: makeFeatureRuntimeTests(), defaultMode: .withFFmpeg)

    func test001_featureRuntimeQueue_queueCompletesTinyTranscode() async throws { try await runner.run(0, in: self) }
    func test002_featureRuntimeTools_ffprobeReadsGeneratedMedia() async throws { try await runner.run(1, in: self) }
    func test003_featureRuntimeQuality_qualityStoreRunsPsnrTask() async throws { try await runner.run(2, in: self) }
    func test004_featureRuntimeMuxMerge_muxingCommandProducesOutput() async throws { try await runner.run(3, in: self) }
    func test005_featureRuntimeMuxMerge_mergingConcatCommandProducesOutput() async throws { try await runner.run(4, in: self) }
    func test006_featureRuntimeQueue_stopMarksRunningLavfiTaskStopped() async throws { try await runner.run(5, in: self) }
}
