import XCTest

final class CommandOnlyXCTests: XCTestCase {
    private let runner = XCTestCaseRunner(tests: makeCommandOnlyTests(), defaultMode: .commandOnly)

    func test001_presetCoding_partialChineseKeysDecodeDefaults() throws { try runner.run(0, in: self) }
    func test002_presetCoding_roundTripsChineseKeys() throws { try runner.run(1, in: self) }
    func test003_settingsCoding_decodesMissingPresetAutoloadFields() throws { try runner.run(2, in: self) }
    func test004_basicCommand_buildsVideoAndAudioCommand() throws { try runner.run(3, in: self) }
    func test005_basicCommand_normalizesQualityArgumentNames() throws { try runner.run(4, in: self) }
    func test006_outputSettings_outputPathNamingAndOmittedOutput() throws { try runner.run(5, in: self) }
    func test007_decoding_addsDecoderAndHardwareArguments() throws { try runner.run(6, in: self) }
    func test008_videoEncoder_addsGenericEncoderFields() throws { try runner.run(7, in: self) }
    func test009_videoToolbox_capabilityDefaults() throws { try runner.run(8, in: self) }
    func test010_videoToolbox_skipsGenericEncoderOptions() throws { try runner.run(9, in: self) }
    func test011_videoToolbox_probeParser() throws { try runner.run(10, in: self) }
    func test012_videoFrame_buildsFrameAndTransformFilters() throws { try runner.run(11, in: self) }
    func test013_videoQuality_buildsQualityAndBitrateArguments() throws { try runner.run(12, in: self) }
    func test014_color_buildsPixelFormatColorAndEqFilters() throws { try runner.run(13, in: self) }
    func test015_commonFilters_buildsDenoiseSharpenAndSubtitleBurn() throws { try runner.run(14, in: self) }
    func test016_frameServer_switchesInputPathForScriptModes() throws { try runner.run(15, in: self) }
    func test017_audio_buildsEncoderQualityChannelSampleRateAndLoudnorm() throws { try runner.run(16, in: self) }
    func test018_audio_disablesAudio() throws { try runner.run(17, in: self) }
    func test019_image_buildsImageEncoderAndQuality() throws { try runner.run(18, in: self) }
    func test020_customArguments_addsAllCustomArgumentPositions() throws { try runner.run(19, in: self) }
    func test021_customArguments_fullCustomReplacesPlaceholders() throws { try runner.run(20, in: self) }
    func test022_customArguments_filterComplexReplacesSimpleFilters() throws { try runner.run(21, in: self) }
    func test023_clip_buildsRoughPreciseAndPreseekClipping() throws { try runner.run(22, in: self) }
    func test024_streamControl_indexesVideoAndAudioParameters() throws { try runner.run(23, in: self) }
    func test025_streamControl_buildsSubtitleMetadataChapterAttachmentOptions() throws { try runner.run(24, in: self) }
    func test026_autoMux_addsSidecarSubtitleInputsWhenFilesExist() throws { try runner.run(25, in: self) }
    func test027_progressParser_parsesDurationAndProgressLine() throws { try runner.run(26, in: self) }
    func test028_progressParser_ignoresPlaceholderQuality() throws { try runner.run(27, in: self) }
    func test029_shell_splitsQuotedCommand() throws { try runner.run(28, in: self) }
    func test030_schemeManagement_settingsPersistPresetAutoloadChoices() throws { try runner.run(29, in: self) }
    func test031_muxing_buildsMappedCopyCommand() throws { try runner.run(30, in: self) }
    func test032_merging_buildsConcatDemuxerCommandAndBody() throws { try runner.run(31, in: self) }
    func test033_qualityAssessment_buildsMetricCommands() throws { try runner.run(32, in: self) }
    func test034_qualityAssessment_parsesPsnrSsimAndVmafResults() throws { try runner.run(33, in: self) }
    func test035_performance_collectsNonblockingSnapshot() throws { try runner.run(34, in: self) }
}
