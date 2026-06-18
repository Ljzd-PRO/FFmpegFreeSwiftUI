import XCTest

final class FFmpegRuntimeXCTests: XCTestCase {
    private let runner = XCTestCaseRunner(tests: makeRuntimeTests(), defaultMode: .withFFmpeg)

    func test001_runtimeMedia_generatesTinySourceMedia() throws { try runner.run(0, in: self) }
    func test002_runtimeCommand_basicTranscode() throws { try runner.run(1, in: self) }
    func test003_runtimeCommand_clipAndFilters() throws { try runner.run(2, in: self) }
    func test004_runtimeCommand_subtitleBurn() throws { try runner.run(3, in: self) }
    func test005_runtimeCommand_streamControlAndMovTextSubtitles() throws { try runner.run(4, in: self) }
    func test006_runtimeCommand_autoMuxSidecarSubtitles() throws { try runner.run(5, in: self) }
    func test007_runtimeCommand_imageOutput() throws { try runner.run(6, in: self) }
    func test008_runtimeCommand_h264VideoToolboxSmoke() throws { try runner.run(7, in: self) }
    func test009_runtimeCommand_hevcVideoToolboxSmoke() throws { try runner.run(8, in: self) }
    func test010_runtimeCommand_proresVideoToolboxSmoke() throws { try runner.run(9, in: self) }
    func test011_runtimeQuality_psnrAndSsimSmoke() throws { try runner.run(10, in: self) }
    func test012_runtimeQuality_optionalVmafOrXpsnrSmoke() throws { try runner.run(11, in: self) }
}
