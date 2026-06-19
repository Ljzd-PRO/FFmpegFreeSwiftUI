import XCTest

final class FeatureCommandOnlyXCTests: XCTestCase {
    private let runner = XCTestCaseRunner(tests: makeFeatureCommandOnlyTests(), defaultMode: .commandOnly)

    func test001_featureQueue_addsFilesWithPresetSnapshotAndCustomOutputDirectory() async throws { try await runner.run(0, in: self) }
    func test002_featureQueue_fakeRunnerCompletesTaskAndParsesProgress() async throws { try await runner.run(1, in: self) }
    func test003_featureQueue_pauseResumeStopAndStdinUseFakeProcess() async throws { try await runner.run(2, in: self) }
    func test004_featureQueue_failureCapturesErrorAndResetClearsTransientState() async throws { try await runner.run(3, in: self) }
    func test005_featureQueue_concurrentPendingRespectsMaxSlotsAndAutostarts() async throws { try await runner.run(4, in: self) }
    func test006_featureQueue_remoteParserAddsCommandAndPresetFileTasks() async throws { try await runner.run(5, in: self) }
    func test007_featureTools_ffprobeAndFfplayUseLocatorPathsAndWorkingDirectory() async throws { try await runner.run(6, in: self) }
    func test008_featureQualityStore_enqueuesTasksAndPreservesHistoryInInjectedFile() async throws { try await runner.run(7, in: self) }
    func test009_featureQualityStore_unavailableFiltersMarkTaskFailedWithoutRunningFfmpeg() async throws { try await runner.run(8, in: self) }
    func test010_featureMuxMerge_muxingUniqueMetadataChoicesAndQueueCommandTask() async throws { try await runner.run(9, in: self) }
    func test011_featureMuxMerge_mergingWritesConcatFileToRequestedDirectory() async throws { try await runner.run(10, in: self) }
    func test012_featureSettings_debouncedSettingsSaveWritesDisplayAndLanguageChoices() async throws { try await runner.run(11, in: self) }
    func test013_featureSettings_locatorDerivesAllToolsFromCustomFfmpegPath() async throws { try await runner.run(12, in: self) }
    func test014_featureLocalization_navigationAndFeatureLabelsLocalizeAcrossLanguages() async throws { try await runner.run(13, in: self) }
    func test015_featurePerformance_snapshotValuesStayInValidRanges() async throws { try await runner.run(14, in: self) }
}
