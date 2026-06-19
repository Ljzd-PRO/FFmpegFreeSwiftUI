import XCTest

final class CommandOnlyXCTests: XCTestCase {
    private let runner = XCTestCaseRunner(tests: makeCommandOnlyTests(), defaultMode: .commandOnly)

    func test001_presetCoding_partialChineseKeysDecodeDefaults() async throws { try await runner.run(0, in: self) }
    func test002_presetCoding_roundTripsChineseKeys() async throws { try await runner.run(1, in: self) }
    func test003_settingsCoding_decodesMissingPresetAutoloadFields() async throws { try await runner.run(2, in: self) }
    func test004_settingsCoding_normalizesLegacyLanguageValues() async throws { try await runner.run(3, in: self) }
    func test005_settingsCoding_normalizesDisplayPreferenceValues() async throws { try await runner.run(4, in: self) }
    func test006_localization_translatesCommonUIText() async throws { try await runner.run(5, in: self) }
    func test007_ffmpegLocator_derivesSiblingFfprobeAndFfplayOverrides() async throws { try await runner.run(6, in: self) }
    func test008_basicCommand_buildsVideoAndAudioCommand() async throws { try await runner.run(7, in: self) }
    func test009_basicCommand_normalizesQualityArgumentNames() async throws { try await runner.run(8, in: self) }
    func test010_outputSettings_outputPathNamingAndOmittedOutput() async throws { try await runner.run(9, in: self) }
    func test011_decoding_addsDecoderAndHardwareArguments() async throws { try await runner.run(10, in: self) }
    func test012_videoEncoder_addsGenericEncoderFields() async throws { try await runner.run(11, in: self) }
    func test013_videoToolbox_capabilityDefaults() async throws { try await runner.run(12, in: self) }
    func test014_videoToolbox_skipsGenericEncoderOptions() async throws { try await runner.run(13, in: self) }
    func test015_videoToolbox_probeParser() async throws { try await runner.run(14, in: self) }
    func test016_videoFrame_buildsFrameAndTransformFilters() async throws { try await runner.run(15, in: self) }
    func test017_videoQuality_buildsQualityAndBitrateArguments() async throws { try await runner.run(16, in: self) }
    func test018_color_buildsPixelFormatColorAndEqFilters() async throws { try await runner.run(17, in: self) }
    func test019_commonFilters_buildsDenoiseSharpenAndSubtitleBurn() async throws { try await runner.run(18, in: self) }
    func test020_frameServer_switchesInputPathForScriptModes() async throws { try await runner.run(19, in: self) }
    func test021_audio_buildsEncoderQualityChannelSampleRateAndLoudnorm() async throws { try await runner.run(20, in: self) }
    func test022_audio_disablesAudio() async throws { try await runner.run(21, in: self) }
    func test023_image_buildsImageEncoderAndQuality() async throws { try await runner.run(22, in: self) }
    func test024_customArguments_addsAllCustomArgumentPositions() async throws { try await runner.run(23, in: self) }
    func test025_customArguments_fullCustomReplacesPlaceholders() async throws { try await runner.run(24, in: self) }
    func test026_customArguments_filterComplexReplacesSimpleFilters() async throws { try await runner.run(25, in: self) }
    func test027_clip_buildsRoughPreciseAndPreseekClipping() async throws { try await runner.run(26, in: self) }
    func test028_streamControl_indexesVideoAndAudioParameters() async throws { try await runner.run(27, in: self) }
    func test029_streamControl_buildsSubtitleMetadataChapterAttachmentOptions() async throws { try await runner.run(28, in: self) }
    func test030_autoMux_addsSidecarSubtitleInputsWhenFilesExist() async throws { try await runner.run(29, in: self) }
    func test031_progressParser_parsesDurationAndProgressLine() async throws { try await runner.run(30, in: self) }
    func test032_progressParser_ignoresPlaceholderQuality() async throws { try await runner.run(31, in: self) }
    func test033_shell_splitsQuotedCommand() async throws { try await runner.run(32, in: self) }
    func test034_schemeManagement_settingsPersistPresetAutoloadChoices() async throws { try await runner.run(33, in: self) }
    func test035_muxing_buildsMappedCopyCommand() async throws { try await runner.run(34, in: self) }
    func test036_merging_buildsConcatDemuxerCommandAndBody() async throws { try await runner.run(35, in: self) }
    func test037_qualityAssessment_buildsMetricCommands() async throws { try await runner.run(36, in: self) }
    func test038_qualityAssessment_parsesPsnrSsimAndVmafResults() async throws { try await runner.run(37, in: self) }
    func test039_performance_collectsNonblockingSnapshot() async throws { try await runner.run(38, in: self) }
}
