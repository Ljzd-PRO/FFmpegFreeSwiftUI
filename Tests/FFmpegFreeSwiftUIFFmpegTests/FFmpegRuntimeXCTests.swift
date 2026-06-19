import XCTest

final class FFmpegRuntimeXCTests: XCTestCase {
    private let runner = XCTestCaseRunner(tests: makeRuntimeTests(), defaultMode: .withFFmpeg)

    func test001_runtimeMedia_generatesTinySourceMedia() async throws { try await runner.run(0, in: self) }
    func test002_runtimeCommand_basicTranscode() async throws { try await runner.run(1, in: self) }
    func test003_runtimeCommand_clipAndFilters() async throws { try await runner.run(2, in: self) }
    func test004_runtimeCommand_subtitleBurn() async throws { try await runner.run(3, in: self) }
    func test005_runtimeCommand_streamControlAndMovTextSubtitles() async throws { try await runner.run(4, in: self) }
    func test006_runtimeCommand_autoMuxSidecarSubtitles() async throws { try await runner.run(5, in: self) }
    func test007_runtimeCommand_imageOutput() async throws { try await runner.run(6, in: self) }
    func test008_runtimeCommand_h264VideoToolboxSmoke() async throws { try await runner.run(7, in: self) }
    func test009_runtimeCommand_hevcVideoToolboxSmoke() async throws { try await runner.run(8, in: self) }
    func test010_runtimeCommand_proresVideoToolboxSmoke() async throws { try await runner.run(9, in: self) }
    func test011_runtimeQuality_psnrAndSsimSmoke() async throws { try await runner.run(10, in: self) }
    func test012_runtimeQuality_optionalVmafOrXpsnrSmoke() async throws { try await runner.run(11, in: self) }
}
