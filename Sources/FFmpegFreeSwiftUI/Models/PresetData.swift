import Foundation

public struct FFColor: Codable, Equatable, Sendable {
    public var alpha: Int
    public var red: Int
    public var green: Int
    public var blue: Int

    public init(alpha: Int = 0, red: Int = 0, green: Int = 0, blue: Int = 0) {
        self.alpha = alpha
        self.red = red
        self.green = green
        self.blue = blue
    }

    public var isTransparent: Bool {
        alpha == 0 && red == 0 && green == 0 && blue == 0
    }
}

public struct PresetData: Codable, Equatable, Sendable {
    public enum AutoNamingOption: Int, Codable, CaseIterable, Sendable {
        case timestamp = 0
        case incrementNumber = 1
        case append3FUI = 2
        case encoderAndQuality = 3
        case random8Digits = 4
        case random8Letters = 5
        case random8Alphanumeric = 6
        case random16Digits = 7
        case random16Letters = 8
        case random16Alphanumeric = 9
    }

    public enum ClipMethod: Int, Codable, Sendable {
        case unknown = 0
        case rough = 1
        case preciseFromStart = 2
        case preciseWithPreseek = 3
        case trimFilter = 4
        case trimHeadTail = 5
    }

    public var outputContainer: String
    public var useAutoNaming: Bool
    public var autoNamingOption: AutoNamingOption
    public var omitOutputFileArgument: Bool
    public var outputNamePrefix: String
    public var outputNameReplacement: String
    public var outputNameSuffix: String
    public var preserveCreationDate: Bool
    public var preserveModificationDate: Bool
    public var preserveAccessDate: Bool

    public var decoder: String
    public var decoderCPUThreads: String
    public var decoderOutputFormat: String
    public var decoderHardwareArgumentName: String
    public var decoderHardwareArgument: String

    public var videoEncoderCategory: String
    public var videoEncoder: String
    public var videoPreset: String
    public var videoProfile: String
    public var videoTune: String
    public var videoGPU: String
    public var videoThreads: String
    public var videoResolution: String
    public var videoAutoWidth: String
    public var videoAutoHeight: String
    public var videoCrop: String
    public var videoFrameRate: String
    public var decimateMaxChangeRatio: String

    public var interpolateTargetFPS: String
    public var interpolateMode: String
    public var interpolateME: String
    public var interpolateSearchAlgorithm: String
    public var interpolateMCMode: String
    public var interpolateVariableBlock: Bool
    public var interpolateBlockSize: String
    public var interpolateSearchRange: String
    public var interpolateSceneChange: String

    public var blendTargetFPS: String
    public var blendMode: String
    public var blendRatio: String
    public var upscaleWidth: String
    public var upscaleHeight: String
    public var upscaleAlgorithm: String
    public var downscaleAlgorithm: String
    public var antiRingingStrength: String
    public var shaderList: [String]

    public var subtitleBurnFilter: String
    public var subtitleFormatPriority: [Int]
    public var subtitleExternalSource: Bool
    public var externalSubtitleFileName: String
    public var externalSubtitleDirectory: String
    public var subtitleEmbeddedSource: Bool
    public var embeddedSubtitleStream: String
    public var subtitleFontsDirectory: String
    public var subtitleStyleName: String
    public var subtitleStyleSize: Float
    public var subtitleBold: Bool
    public var subtitleItalic: Bool
    public var subtitleUnderline: Bool
    public var subtitleStrikeout: Bool
    public var subtitleBorderStyle: Int
    public var subtitleOutlineWidth: String
    public var subtitleShadowDistance: String
    public var subtitlePrimaryColor: FFColor
    public var subtitlePrimaryAlpha: String
    public var subtitleSecondaryColor: FFColor
    public var subtitleSecondaryAlpha: String
    public var subtitleOutlineColor: FFColor
    public var subtitleOutlineAlpha: String
    public var subtitleBackColor: FFColor
    public var subtitleBackAlpha: String
    public var subtitleAlignment: Int
    public var subtitleMarginV: String
    public var subtitleMarginL: String
    public var subtitleMarginR: String
    public var subtitleSpacing: String
    public var subtitleLineSpacing: String
    public var subtitleResolution: String
    public var subtitleCustomStyle: String
    public var subtitleCustomFilterArguments: String

    public var bitrateControlMode: String
    public var qualityArgumentName: String
    public var qualityValue: String
    public var bitrateBase: String
    public var bitrateMin: String
    public var bitrateMax: String
    public var bitrateBuffer: String
    public var advancedQualityArguments: [String]

    public var pixelFormat: String
    public var colorFilter: String
    public var colorMatrix: String
    public var colorPrimaries: String
    public var colorTransfer: String
    public var colorRange: String
    public var tonemapAlgorithm: String
    public var colorProcessMode: String
    public var brightness: String
    public var contrast: String
    public var saturation: String
    public var gamma: String

    public var denoiseMode: String
    public var denoiseParameter1: String
    public var denoiseParameter2: String
    public var denoiseParameter3: String
    public var denoiseParameter4: String
    public var sharpenWidth: String
    public var sharpenHeight: String
    public var sharpenStrength: String
    public var deinterlaceMode: Int
    public var rotateMode: Int
    public var mirrorMode: Int

    public var useAviSynth: Bool
    public var aviSynthScript: String
    public var useVapourSynth: Bool
    public var vapourSynthScript: String

    public var audioEncoder: String
    public var audioBitrate: String
    public var audioQualityArgumentName: String
    public var audioQualityValue: String
    public var audioChannels: String
    public var audioSampleRate: String
    public var loudnormTarget: String
    public var loudnormRange: String
    public var loudnormPeak: String

    public var imageEncoder: String
    public var imageQuality: String

    public var customVideoFilter: String
    public var customAudioFilter: String
    public var customFilterComplex: String
    public var customVideoArguments: String
    public var customAudioArguments: String
    public var customLeadingArguments: String
    public var customBeforeOutputArguments: String
    public var customAfterOutputArguments: String
    public var customTrailingArguments: String
    public var customFullArguments: String

    public var clipMethod: ClipMethod
    public var clipInPoint: String
    public var clipOutPoint: String
    public var clipPreDecodeSeconds: String

    public var keepOtherVideoStreams: Bool
    public var videoStreamTargets: [String]
    public var keepOtherAudioStreams: Bool
    public var audioStreamTargets: [String]
    public var subtitleStreamTargets: [String]
    public var subtitleOperation: Int
    public var keepOtherSubtitleStreams: Bool
    public var autoMuxSRT: Bool
    public var autoMuxASS: Bool
    public var autoMuxSSA: Bool
    public var autoMuxSubtitleToMovText: Bool
    public var metadataOption: Int
    public var chapterOption: Int
    public var attachmentOption: Int

    public var computerName: String
    public var outputLocation: String

    public init() {
        outputContainer = ""
        useAutoNaming = false
        autoNamingOption = .timestamp
        omitOutputFileArgument = false
        outputNamePrefix = ""
        outputNameReplacement = ""
        outputNameSuffix = ""
        preserveCreationDate = false
        preserveModificationDate = false
        preserveAccessDate = false
        decoder = ""
        decoderCPUThreads = ""
        decoderOutputFormat = ""
        decoderHardwareArgumentName = ""
        decoderHardwareArgument = ""
        videoEncoderCategory = ""
        videoEncoder = ""
        videoPreset = ""
        videoProfile = ""
        videoTune = ""
        videoGPU = ""
        videoThreads = ""
        videoResolution = ""
        videoAutoWidth = ""
        videoAutoHeight = ""
        videoCrop = ""
        videoFrameRate = ""
        decimateMaxChangeRatio = ""
        interpolateTargetFPS = ""
        interpolateMode = ""
        interpolateME = ""
        interpolateSearchAlgorithm = ""
        interpolateMCMode = ""
        interpolateVariableBlock = false
        interpolateBlockSize = ""
        interpolateSearchRange = ""
        interpolateSceneChange = ""
        blendTargetFPS = ""
        blendMode = ""
        blendRatio = ""
        upscaleWidth = ""
        upscaleHeight = ""
        upscaleAlgorithm = ""
        downscaleAlgorithm = ""
        antiRingingStrength = ""
        shaderList = []
        subtitleBurnFilter = ""
        subtitleFormatPriority = [-1, -1, -1]
        subtitleExternalSource = false
        externalSubtitleFileName = ""
        externalSubtitleDirectory = ""
        subtitleEmbeddedSource = false
        embeddedSubtitleStream = ""
        subtitleFontsDirectory = ""
        subtitleStyleName = ""
        subtitleStyleSize = 0
        subtitleBold = false
        subtitleItalic = false
        subtitleUnderline = false
        subtitleStrikeout = false
        subtitleBorderStyle = -1
        subtitleOutlineWidth = ""
        subtitleShadowDistance = ""
        subtitlePrimaryColor = FFColor()
        subtitlePrimaryAlpha = ""
        subtitleSecondaryColor = FFColor()
        subtitleSecondaryAlpha = ""
        subtitleOutlineColor = FFColor()
        subtitleOutlineAlpha = ""
        subtitleBackColor = FFColor()
        subtitleBackAlpha = ""
        subtitleAlignment = -1
        subtitleMarginV = ""
        subtitleMarginL = ""
        subtitleMarginR = ""
        subtitleSpacing = ""
        subtitleLineSpacing = ""
        subtitleResolution = ""
        subtitleCustomStyle = ""
        subtitleCustomFilterArguments = ""
        bitrateControlMode = ""
        qualityArgumentName = ""
        qualityValue = ""
        bitrateBase = ""
        bitrateMin = ""
        bitrateMax = ""
        bitrateBuffer = ""
        advancedQualityArguments = []
        pixelFormat = ""
        colorFilter = ""
        colorMatrix = ""
        colorPrimaries = ""
        colorTransfer = ""
        colorRange = ""
        tonemapAlgorithm = ""
        colorProcessMode = ""
        brightness = ""
        contrast = ""
        saturation = ""
        gamma = ""
        denoiseMode = ""
        denoiseParameter1 = ""
        denoiseParameter2 = ""
        denoiseParameter3 = ""
        denoiseParameter4 = ""
        sharpenWidth = ""
        sharpenHeight = ""
        sharpenStrength = ""
        deinterlaceMode = 0
        rotateMode = 0
        mirrorMode = 0
        useAviSynth = false
        aviSynthScript = ""
        useVapourSynth = false
        vapourSynthScript = ""
        audioEncoder = ""
        audioBitrate = ""
        audioQualityArgumentName = ""
        audioQualityValue = ""
        audioChannels = ""
        audioSampleRate = ""
        loudnormTarget = ""
        loudnormRange = ""
        loudnormPeak = ""
        imageEncoder = ""
        imageQuality = ""
        customVideoFilter = ""
        customAudioFilter = ""
        customFilterComplex = ""
        customVideoArguments = ""
        customAudioArguments = ""
        customLeadingArguments = ""
        customBeforeOutputArguments = ""
        customAfterOutputArguments = ""
        customTrailingArguments = ""
        customFullArguments = ""
        clipMethod = .unknown
        clipInPoint = ""
        clipOutPoint = ""
        clipPreDecodeSeconds = ""
        keepOtherVideoStreams = false
        videoStreamTargets = []
        keepOtherAudioStreams = false
        audioStreamTargets = []
        subtitleStreamTargets = []
        subtitleOperation = 0
        keepOtherSubtitleStreams = false
        autoMuxSRT = false
        autoMuxASS = false
        autoMuxSSA = false
        autoMuxSubtitleToMovText = false
        metadataOption = 0
        chapterOption = 0
        attachmentOption = 0
        computerName = Host.current().localizedName ?? ""
        outputLocation = ""
    }

    public init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        outputContainer = container.decodeDefault(String.self, forKey: .outputContainer, default: outputContainer)
        useAutoNaming = container.decodeDefault(Bool.self, forKey: .useAutoNaming, default: useAutoNaming)
        autoNamingOption = container.decodeDefault(AutoNamingOption.self, forKey: .autoNamingOption, default: autoNamingOption)
        omitOutputFileArgument = container.decodeDefault(Bool.self, forKey: .omitOutputFileArgument, default: omitOutputFileArgument)
        outputNamePrefix = container.decodeDefault(String.self, forKey: .outputNamePrefix, default: outputNamePrefix)
        outputNameReplacement = container.decodeDefault(String.self, forKey: .outputNameReplacement, default: outputNameReplacement)
        outputNameSuffix = container.decodeDefault(String.self, forKey: .outputNameSuffix, default: outputNameSuffix)
        preserveCreationDate = container.decodeDefault(Bool.self, forKey: .preserveCreationDate, default: preserveCreationDate)
        preserveModificationDate = container.decodeDefault(Bool.self, forKey: .preserveModificationDate, default: preserveModificationDate)
        preserveAccessDate = container.decodeDefault(Bool.self, forKey: .preserveAccessDate, default: preserveAccessDate)
        self.decoder = container.decodeDefault(String.self, forKey: .decoder, default: self.decoder)
        decoderCPUThreads = container.decodeDefault(String.self, forKey: .decoderCPUThreads, default: decoderCPUThreads)
        decoderOutputFormat = container.decodeDefault(String.self, forKey: .decoderOutputFormat, default: decoderOutputFormat)
        decoderHardwareArgumentName = container.decodeDefault(String.self, forKey: .decoderHardwareArgumentName, default: decoderHardwareArgumentName)
        decoderHardwareArgument = container.decodeDefault(String.self, forKey: .decoderHardwareArgument, default: decoderHardwareArgument)
        videoEncoderCategory = container.decodeDefault(String.self, forKey: .videoEncoderCategory, default: videoEncoderCategory)
        videoEncoder = container.decodeDefault(String.self, forKey: .videoEncoder, default: videoEncoder)
        videoPreset = container.decodeDefault(String.self, forKey: .videoPreset, default: videoPreset)
        videoProfile = container.decodeDefault(String.self, forKey: .videoProfile, default: videoProfile)
        videoTune = container.decodeDefault(String.self, forKey: .videoTune, default: videoTune)
        videoGPU = container.decodeDefault(String.self, forKey: .videoGPU, default: videoGPU)
        videoThreads = container.decodeDefault(String.self, forKey: .videoThreads, default: videoThreads)
        videoResolution = container.decodeDefault(String.self, forKey: .videoResolution, default: videoResolution)
        videoAutoWidth = container.decodeDefault(String.self, forKey: .videoAutoWidth, default: videoAutoWidth)
        videoAutoHeight = container.decodeDefault(String.self, forKey: .videoAutoHeight, default: videoAutoHeight)
        videoCrop = container.decodeDefault(String.self, forKey: .videoCrop, default: videoCrop)
        videoFrameRate = container.decodeDefault(String.self, forKey: .videoFrameRate, default: videoFrameRate)
        decimateMaxChangeRatio = container.decodeDefault(String.self, forKey: .decimateMaxChangeRatio, default: decimateMaxChangeRatio)
        interpolateTargetFPS = container.decodeDefault(String.self, forKey: .interpolateTargetFPS, default: interpolateTargetFPS)
        interpolateMode = container.decodeDefault(String.self, forKey: .interpolateMode, default: interpolateMode)
        interpolateME = container.decodeDefault(String.self, forKey: .interpolateME, default: interpolateME)
        interpolateSearchAlgorithm = container.decodeDefault(String.self, forKey: .interpolateSearchAlgorithm, default: interpolateSearchAlgorithm)
        interpolateMCMode = container.decodeDefault(String.self, forKey: .interpolateMCMode, default: interpolateMCMode)
        interpolateVariableBlock = container.decodeDefault(Bool.self, forKey: .interpolateVariableBlock, default: interpolateVariableBlock)
        interpolateBlockSize = container.decodeDefault(String.self, forKey: .interpolateBlockSize, default: interpolateBlockSize)
        interpolateSearchRange = container.decodeDefault(String.self, forKey: .interpolateSearchRange, default: interpolateSearchRange)
        interpolateSceneChange = container.decodeDefault(String.self, forKey: .interpolateSceneChange, default: interpolateSceneChange)
        blendTargetFPS = container.decodeDefault(String.self, forKey: .blendTargetFPS, default: blendTargetFPS)
        blendMode = container.decodeDefault(String.self, forKey: .blendMode, default: blendMode)
        blendRatio = container.decodeDefault(String.self, forKey: .blendRatio, default: blendRatio)
        upscaleWidth = container.decodeDefault(String.self, forKey: .upscaleWidth, default: upscaleWidth)
        upscaleHeight = container.decodeDefault(String.self, forKey: .upscaleHeight, default: upscaleHeight)
        upscaleAlgorithm = container.decodeDefault(String.self, forKey: .upscaleAlgorithm, default: upscaleAlgorithm)
        downscaleAlgorithm = container.decodeDefault(String.self, forKey: .downscaleAlgorithm, default: downscaleAlgorithm)
        antiRingingStrength = container.decodeDefault(String.self, forKey: .antiRingingStrength, default: antiRingingStrength)
        shaderList = container.decodeStringArray(forKey: .shaderList, default: shaderList)
        subtitleBurnFilter = container.decodeDefault(String.self, forKey: .subtitleBurnFilter, default: subtitleBurnFilter)
        subtitleFormatPriority = container.decodeIntArray(forKey: .subtitleFormatPriority, default: subtitleFormatPriority)
        subtitleExternalSource = container.decodeDefault(Bool.self, forKey: .subtitleExternalSource, default: subtitleExternalSource)
        externalSubtitleFileName = container.decodeDefault(String.self, forKey: .externalSubtitleFileName, default: externalSubtitleFileName)
        externalSubtitleDirectory = container.decodeDefault(String.self, forKey: .externalSubtitleDirectory, default: externalSubtitleDirectory)
        subtitleEmbeddedSource = container.decodeDefault(Bool.self, forKey: .subtitleEmbeddedSource, default: subtitleEmbeddedSource)
        embeddedSubtitleStream = container.decodeDefault(String.self, forKey: .embeddedSubtitleStream, default: embeddedSubtitleStream)
        subtitleFontsDirectory = container.decodeDefault(String.self, forKey: .subtitleFontsDirectory, default: subtitleFontsDirectory)
        subtitleStyleName = container.decodeDefault(String.self, forKey: .subtitleStyleName, default: subtitleStyleName)
        subtitleStyleSize = container.decodeDefault(Float.self, forKey: .subtitleStyleSize, default: subtitleStyleSize)
        subtitleBold = container.decodeDefault(Bool.self, forKey: .subtitleBold, default: subtitleBold)
        subtitleItalic = container.decodeDefault(Bool.self, forKey: .subtitleItalic, default: subtitleItalic)
        subtitleUnderline = container.decodeDefault(Bool.self, forKey: .subtitleUnderline, default: subtitleUnderline)
        subtitleStrikeout = container.decodeDefault(Bool.self, forKey: .subtitleStrikeout, default: subtitleStrikeout)
        subtitleBorderStyle = container.decodeDefault(Int.self, forKey: .subtitleBorderStyle, default: subtitleBorderStyle)
        subtitleOutlineWidth = container.decodeDefault(String.self, forKey: .subtitleOutlineWidth, default: subtitleOutlineWidth)
        subtitleShadowDistance = container.decodeDefault(String.self, forKey: .subtitleShadowDistance, default: subtitleShadowDistance)
        subtitlePrimaryColor = container.decodeDefault(FFColor.self, forKey: .subtitlePrimaryColor, default: subtitlePrimaryColor)
        subtitlePrimaryAlpha = container.decodeDefault(String.self, forKey: .subtitlePrimaryAlpha, default: subtitlePrimaryAlpha)
        subtitleSecondaryColor = container.decodeDefault(FFColor.self, forKey: .subtitleSecondaryColor, default: subtitleSecondaryColor)
        subtitleSecondaryAlpha = container.decodeDefault(String.self, forKey: .subtitleSecondaryAlpha, default: subtitleSecondaryAlpha)
        subtitleOutlineColor = container.decodeDefault(FFColor.self, forKey: .subtitleOutlineColor, default: subtitleOutlineColor)
        subtitleOutlineAlpha = container.decodeDefault(String.self, forKey: .subtitleOutlineAlpha, default: subtitleOutlineAlpha)
        subtitleBackColor = container.decodeDefault(FFColor.self, forKey: .subtitleBackColor, default: subtitleBackColor)
        subtitleBackAlpha = container.decodeDefault(String.self, forKey: .subtitleBackAlpha, default: subtitleBackAlpha)
        subtitleAlignment = container.decodeDefault(Int.self, forKey: .subtitleAlignment, default: subtitleAlignment)
        subtitleMarginV = container.decodeDefault(String.self, forKey: .subtitleMarginV, default: subtitleMarginV)
        subtitleMarginL = container.decodeDefault(String.self, forKey: .subtitleMarginL, default: subtitleMarginL)
        subtitleMarginR = container.decodeDefault(String.self, forKey: .subtitleMarginR, default: subtitleMarginR)
        subtitleSpacing = container.decodeDefault(String.self, forKey: .subtitleSpacing, default: subtitleSpacing)
        subtitleLineSpacing = container.decodeDefault(String.self, forKey: .subtitleLineSpacing, default: subtitleLineSpacing)
        subtitleResolution = container.decodeDefault(String.self, forKey: .subtitleResolution, default: subtitleResolution)
        subtitleCustomStyle = container.decodeDefault(String.self, forKey: .subtitleCustomStyle, default: subtitleCustomStyle)
        subtitleCustomFilterArguments = container.decodeDefault(String.self, forKey: .subtitleCustomFilterArguments, default: subtitleCustomFilterArguments)
        bitrateControlMode = container.decodeDefault(String.self, forKey: .bitrateControlMode, default: bitrateControlMode)
        qualityArgumentName = container.decodeDefault(String.self, forKey: .qualityArgumentName, default: qualityArgumentName)
        qualityValue = container.decodeDefault(String.self, forKey: .qualityValue, default: qualityValue)
        bitrateBase = container.decodeDefault(String.self, forKey: .bitrateBase, default: bitrateBase)
        bitrateMin = container.decodeDefault(String.self, forKey: .bitrateMin, default: bitrateMin)
        bitrateMax = container.decodeDefault(String.self, forKey: .bitrateMax, default: bitrateMax)
        bitrateBuffer = container.decodeDefault(String.self, forKey: .bitrateBuffer, default: bitrateBuffer)
        advancedQualityArguments = container.decodeStringArray(forKey: .advancedQualityArguments, default: advancedQualityArguments)
        pixelFormat = container.decodeDefault(String.self, forKey: .pixelFormat, default: pixelFormat)
        colorFilter = container.decodeDefault(String.self, forKey: .colorFilter, default: colorFilter)
        colorMatrix = container.decodeDefault(String.self, forKey: .colorMatrix, default: colorMatrix)
        colorPrimaries = container.decodeDefault(String.self, forKey: .colorPrimaries, default: colorPrimaries)
        colorTransfer = container.decodeDefault(String.self, forKey: .colorTransfer, default: colorTransfer)
        colorRange = container.decodeDefault(String.self, forKey: .colorRange, default: colorRange)
        tonemapAlgorithm = container.decodeDefault(String.self, forKey: .tonemapAlgorithm, default: tonemapAlgorithm)
        colorProcessMode = container.decodeDefault(String.self, forKey: .colorProcessMode, default: colorProcessMode)
        brightness = container.decodeDefault(String.self, forKey: .brightness, default: brightness)
        contrast = container.decodeDefault(String.self, forKey: .contrast, default: contrast)
        saturation = container.decodeDefault(String.self, forKey: .saturation, default: saturation)
        gamma = container.decodeDefault(String.self, forKey: .gamma, default: gamma)
        denoiseMode = container.decodeDefault(String.self, forKey: .denoiseMode, default: denoiseMode)
        denoiseParameter1 = container.decodeDefault(String.self, forKey: .denoiseParameter1, default: denoiseParameter1)
        denoiseParameter2 = container.decodeDefault(String.self, forKey: .denoiseParameter2, default: denoiseParameter2)
        denoiseParameter3 = container.decodeDefault(String.self, forKey: .denoiseParameter3, default: denoiseParameter3)
        denoiseParameter4 = container.decodeDefault(String.self, forKey: .denoiseParameter4, default: denoiseParameter4)
        sharpenWidth = container.decodeDefault(String.self, forKey: .sharpenWidth, default: sharpenWidth)
        sharpenHeight = container.decodeDefault(String.self, forKey: .sharpenHeight, default: sharpenHeight)
        sharpenStrength = container.decodeDefault(String.self, forKey: .sharpenStrength, default: sharpenStrength)
        deinterlaceMode = container.decodeDefault(Int.self, forKey: .deinterlaceMode, default: deinterlaceMode)
        rotateMode = container.decodeDefault(Int.self, forKey: .rotateMode, default: rotateMode)
        mirrorMode = container.decodeDefault(Int.self, forKey: .mirrorMode, default: mirrorMode)
        useAviSynth = container.decodeDefault(Bool.self, forKey: .useAviSynth, default: useAviSynth)
        aviSynthScript = container.decodeDefault(String.self, forKey: .aviSynthScript, default: aviSynthScript)
        useVapourSynth = container.decodeDefault(Bool.self, forKey: .useVapourSynth, default: useVapourSynth)
        vapourSynthScript = container.decodeDefault(String.self, forKey: .vapourSynthScript, default: vapourSynthScript)
        audioEncoder = container.decodeDefault(String.self, forKey: .audioEncoder, default: audioEncoder)
        audioBitrate = container.decodeDefault(String.self, forKey: .audioBitrate, default: audioBitrate)
        audioQualityArgumentName = container.decodeDefault(String.self, forKey: .audioQualityArgumentName, default: audioQualityArgumentName)
        audioQualityValue = container.decodeDefault(String.self, forKey: .audioQualityValue, default: audioQualityValue)
        audioChannels = container.decodeDefault(String.self, forKey: .audioChannels, default: audioChannels)
        audioSampleRate = container.decodeDefault(String.self, forKey: .audioSampleRate, default: audioSampleRate)
        loudnormTarget = container.decodeDefault(String.self, forKey: .loudnormTarget, default: loudnormTarget)
        loudnormRange = container.decodeDefault(String.self, forKey: .loudnormRange, default: loudnormRange)
        loudnormPeak = container.decodeDefault(String.self, forKey: .loudnormPeak, default: loudnormPeak)
        imageEncoder = container.decodeDefault(String.self, forKey: .imageEncoder, default: imageEncoder)
        imageQuality = container.decodeDefault(String.self, forKey: .imageQuality, default: imageQuality)
        customVideoFilter = container.decodeDefault(String.self, forKey: .customVideoFilter, default: customVideoFilter)
        customAudioFilter = container.decodeDefault(String.self, forKey: .customAudioFilter, default: customAudioFilter)
        customFilterComplex = container.decodeDefault(String.self, forKey: .customFilterComplex, default: customFilterComplex)
        customVideoArguments = container.decodeDefault(String.self, forKey: .customVideoArguments, default: customVideoArguments)
        customAudioArguments = container.decodeDefault(String.self, forKey: .customAudioArguments, default: customAudioArguments)
        customLeadingArguments = container.decodeDefault(String.self, forKey: .customLeadingArguments, default: customLeadingArguments)
        customBeforeOutputArguments = container.decodeDefault(String.self, forKey: .customBeforeOutputArguments, default: customBeforeOutputArguments)
        customAfterOutputArguments = container.decodeDefault(String.self, forKey: .customAfterOutputArguments, default: customAfterOutputArguments)
        customTrailingArguments = container.decodeDefault(String.self, forKey: .customTrailingArguments, default: customTrailingArguments)
        customFullArguments = container.decodeDefault(String.self, forKey: .customFullArguments, default: customFullArguments)
        clipMethod = container.decodeDefault(ClipMethod.self, forKey: .clipMethod, default: clipMethod)
        clipInPoint = container.decodeDefault(String.self, forKey: .clipInPoint, default: clipInPoint)
        clipOutPoint = container.decodeDefault(String.self, forKey: .clipOutPoint, default: clipOutPoint)
        clipPreDecodeSeconds = container.decodeDefault(String.self, forKey: .clipPreDecodeSeconds, default: clipPreDecodeSeconds)
        keepOtherVideoStreams = container.decodeDefault(Bool.self, forKey: .keepOtherVideoStreams, default: keepOtherVideoStreams)
        videoStreamTargets = container.decodeStringArray(forKey: .videoStreamTargets, default: videoStreamTargets)
        keepOtherAudioStreams = container.decodeDefault(Bool.self, forKey: .keepOtherAudioStreams, default: keepOtherAudioStreams)
        audioStreamTargets = container.decodeStringArray(forKey: .audioStreamTargets, default: audioStreamTargets)
        subtitleStreamTargets = container.decodeStringArray(forKey: .subtitleStreamTargets, default: subtitleStreamTargets)
        subtitleOperation = container.decodeDefault(Int.self, forKey: .subtitleOperation, default: subtitleOperation)
        keepOtherSubtitleStreams = container.decodeDefault(Bool.self, forKey: .keepOtherSubtitleStreams, default: keepOtherSubtitleStreams)
        autoMuxSRT = container.decodeDefault(Bool.self, forKey: .autoMuxSRT, default: autoMuxSRT)
        autoMuxASS = container.decodeDefault(Bool.self, forKey: .autoMuxASS, default: autoMuxASS)
        autoMuxSSA = container.decodeDefault(Bool.self, forKey: .autoMuxSSA, default: autoMuxSSA)
        autoMuxSubtitleToMovText = container.decodeDefault(Bool.self, forKey: .autoMuxSubtitleToMovText, default: autoMuxSubtitleToMovText)
        metadataOption = container.decodeDefault(Int.self, forKey: .metadataOption, default: metadataOption)
        chapterOption = container.decodeDefault(Int.self, forKey: .chapterOption, default: chapterOption)
        attachmentOption = container.decodeDefault(Int.self, forKey: .attachmentOption, default: attachmentOption)
        computerName = container.decodeDefault(String.self, forKey: .computerName, default: computerName)
        outputLocation = container.decodeDefault(String.self, forKey: .outputLocation, default: outputLocation)
    }

    enum CodingKeys: String, CodingKey {
        case outputContainer = "输出容器"
        case useAutoNaming = "输出命名_使用自动命名"
        case autoNamingOption = "输出命名_自动命名选项"
        case omitOutputFileArgument = "输出命名_不使用输出文件参数"
        case outputNamePrefix = "输出命名_开头文本"
        case outputNameReplacement = "输出命名_替代文本"
        case outputNameSuffix = "输出命名_结尾文本"
        case preserveCreationDate = "输出命名_保留创建时间"
        case preserveModificationDate = "输出命名_保留修改时间"
        case preserveAccessDate = "输出命名_保留访问时间"
        case decoder = "解码参数_解码器"
        case decoderCPUThreads = "解码参数_CPU解码线程数"
        case decoderOutputFormat = "解码参数_解码数据格式"
        case decoderHardwareArgumentName = "解码参数_指定硬件的参数名"
        case decoderHardwareArgument = "解码参数_指定硬件的参数"
        case videoEncoderCategory = "视频参数_编码器_类别"
        case videoEncoder = "视频参数_编码器_具体编码"
        case videoPreset = "视频参数_编码器_编码预设"
        case videoProfile = "视频参数_编码器_配置文件"
        case videoTune = "视频参数_编码器_场景优化"
        case videoGPU = "视频参数_编码器_gpu"
        case videoThreads = "视频参数_编码器_threads"
        case videoResolution = "视频参数_分辨率"
        case videoAutoWidth = "视频参数_分辨率自动计算_宽度"
        case videoAutoHeight = "视频参数_分辨率自动计算_高度"
        case videoCrop = "视频参数_分辨率_裁剪滤镜参数"
        case videoFrameRate = "视频参数_帧速率"
        case decimateMaxChangeRatio = "视频参数_帧速率_抽帧最大变化比例"
        case interpolateTargetFPS = "视频参数_插帧_目标帧率"
        case interpolateMode = "视频参数_插帧_插帧模式"
        case interpolateME = "视频参数_插帧_运动估计模式"
        case interpolateSearchAlgorithm = "视频参数_插帧_运动估计算法"
        case interpolateMCMode = "视频参数_插帧_运动补偿模式"
        case interpolateVariableBlock = "视频参数_插帧_可变块大小的运动补偿"
        case interpolateBlockSize = "视频参数_插帧_块大小"
        case interpolateSearchRange = "视频参数_插帧_搜索范围"
        case interpolateSceneChange = "视频参数_插帧_场景变化检测强度"
        case blendTargetFPS = "视频参数_帧混合_指定帧率"
        case blendMode = "视频参数_帧混合_混合模式"
        case blendRatio = "视频参数_帧混合_混合比例"
        case upscaleWidth = "视频参数_超分_目标宽度"
        case upscaleHeight = "视频参数_超分_目标高度"
        case upscaleAlgorithm = "视频参数_超分_上采样算法"
        case downscaleAlgorithm = "视频参数_超分_下采样算法"
        case antiRingingStrength = "视频参数_超分_抗振铃强度"
        case shaderList = "视频参数_超分_着色器列表"
        case subtitleBurnFilter = "视频参数_烧录字幕_滤镜选择"
        case subtitleFormatPriority = "视频参数_烧录字幕_字幕格式优先级"
        case subtitleExternalSource = "视频参数_烧录字幕_字幕来源是外部文件"
        case externalSubtitleFileName = "视频参数_烧录字幕_外部字幕文件名"
        case externalSubtitleDirectory = "视频参数_烧录字幕_外部字幕文件夹位置"
        case subtitleEmbeddedSource = "视频参数_烧录字幕_字幕来源是内嵌的流"
        case embeddedSubtitleStream = "视频参数_烧录字幕_指定内嵌的流"
        case subtitleFontsDirectory = "视频参数_烧录字幕_字体文件夹"
        case subtitleStyleName = "视频参数_烧录字幕_基本样式_名称"
        case subtitleStyleSize = "视频参数_烧录字幕_基本样式_大小"
        case subtitleBold = "视频参数_烧录字幕_基本样式_粗体"
        case subtitleItalic = "视频参数_烧录字幕_基本样式_斜体"
        case subtitleUnderline = "视频参数_烧录字幕_基本样式_下划线"
        case subtitleStrikeout = "视频参数_烧录字幕_基本样式_删除线"
        case subtitleBorderStyle = "视频参数_烧录字幕_边框样式"
        case subtitleOutlineWidth = "视频参数_烧录字幕_描边宽度"
        case subtitleShadowDistance = "视频参数_烧录字幕_阴影距离"
        case subtitlePrimaryColor = "视频参数_烧录字幕_主要颜色"
        case subtitlePrimaryAlpha = "视频参数_烧录字幕_主要颜色_透明度"
        case subtitleSecondaryColor = "视频参数_烧录字幕_次要颜色"
        case subtitleSecondaryAlpha = "视频参数_烧录字幕_次要颜色_透明度"
        case subtitleOutlineColor = "视频参数_烧录字幕_描边颜色"
        case subtitleOutlineAlpha = "视频参数_烧录字幕_描边颜色_透明度"
        case subtitleBackColor = "视频参数_烧录字幕_背景颜色"
        case subtitleBackAlpha = "视频参数_烧录字幕_背景颜色_透明度"
        case subtitleAlignment = "视频参数_烧录字幕_对齐方位"
        case subtitleMarginV = "视频参数_烧录字幕_垂直边距"
        case subtitleMarginL = "视频参数_烧录字幕_左边距"
        case subtitleMarginR = "视频参数_烧录字幕_右边距"
        case subtitleSpacing = "视频参数_烧录字幕_字距"
        case subtitleLineSpacing = "视频参数_烧录字幕_行距"
        case subtitleResolution = "视频参数_烧录字幕_视频分辨率"
        case subtitleCustomStyle = "视频参数_烧录字幕_自定义样式"
        case subtitleCustomFilterArguments = "视频参数_烧录字幕_自定义滤镜参数"
        case bitrateControlMode = "视频参数_比特率_控制方式"
        case qualityArgumentName = "视频参数_质量控制_参数名"
        case qualityValue = "视频参数_质量控制_值"
        case bitrateBase = "视频参数_比特率_基础"
        case bitrateMin = "视频参数_比特率_最低值"
        case bitrateMax = "视频参数_比特率_最高值"
        case bitrateBuffer = "视频参数_比特率_缓冲区"
        case advancedQualityArguments = "视频参数_质量控制_进阶参数集"
        case pixelFormat = "视频参数_色彩管理_像素格式"
        case colorFilter = "视频参数_色彩管理_滤镜选择"
        case colorMatrix = "视频参数_色彩管理_矩阵系数"
        case colorPrimaries = "视频参数_色彩管理_色域"
        case colorTransfer = "视频参数_色彩管理_传输特性"
        case colorRange = "视频参数_色彩管理_范围"
        case tonemapAlgorithm = "视频参数_色彩管理_色调映射算法"
        case colorProcessMode = "视频参数_色彩管理_处理方式"
        case brightness = "视频参数_色彩管理_亮度"
        case contrast = "视频参数_色彩管理_对比度"
        case saturation = "视频参数_色彩管理_饱和度"
        case gamma = "视频参数_色彩管理_伽马"
        case denoiseMode = "视频参数_降噪_方式"
        case denoiseParameter1 = "视频参数_降噪_参数1"
        case denoiseParameter2 = "视频参数_降噪_参数2"
        case denoiseParameter3 = "视频参数_降噪_参数3"
        case denoiseParameter4 = "视频参数_降噪_参数4"
        case sharpenWidth = "视频参数_锐化_水平尺寸"
        case sharpenHeight = "视频参数_锐化_垂直尺寸"
        case sharpenStrength = "视频参数_锐化_锐化强度"
        case deinterlaceMode = "视频参数_逐行与隔行"
        case rotateMode = "视频参数_画面翻转_角度翻转"
        case mirrorMode = "视频参数_画面翻转_镜像翻转"
        case useAviSynth = "视频参数_视频帧服务器_使用AviSynth"
        case aviSynthScript = "视频参数_视频帧服务器_avs脚本文件"
        case useVapourSynth = "视频参数_视频帧服务器_使用VapourSynth"
        case vapourSynthScript = "视频参数_视频帧服务器_vpy脚本文件"
        case audioEncoder = "音频参数_编码器_具体编码"
        case audioBitrate = "音频参数_比特率"
        case audioQualityArgumentName = "音频参数_质量参数名"
        case audioQualityValue = "音频参数_质量值"
        case audioChannels = "音频参数_声道数"
        case audioSampleRate = "音频参数_采样率"
        case loudnormTarget = "音频参数_响度标准化_目标响度"
        case loudnormRange = "音频参数_响度标准化_动态范围"
        case loudnormPeak = "音频参数_响度标准化_峰值电平"
        case imageEncoder = "图片参数_编码器_编码名称"
        case imageQuality = "图片参数_编码器_质量值"
        case customVideoFilter = "自定义参数_视频滤镜"
        case customAudioFilter = "自定义参数_音频滤镜"
        case customFilterComplex = "自定义参数_filter_complex"
        case customVideoArguments = "自定义参数_视频参数"
        case customAudioArguments = "自定义参数_音频参数"
        case customLeadingArguments = "自定义参数_开头参数"
        case customBeforeOutputArguments = "自定义参数_之前参数"
        case customAfterOutputArguments = "自定义参数_之后参数"
        case customTrailingArguments = "自定义参数_最后参数"
        case customFullArguments = "自定义参数_完全自己写"
        case clipMethod = "剪辑区间_方法"
        case clipInPoint = "剪辑区间_入点"
        case clipOutPoint = "剪辑区间_出点"
        case clipPreDecodeSeconds = "剪辑区间_向前解码多久秒"
        case keepOtherVideoStreams = "流控制_启用保留其他视频流"
        case videoStreamTargets = "流控制_将视频参数应用于指定流"
        case keepOtherAudioStreams = "流控制_启用保留其他音频流"
        case audioStreamTargets = "流控制_将音频参数应用于指定流"
        case subtitleStreamTargets = "流控制_将字幕参数应用于指定流"
        case subtitleOperation = "流控制_如何操作指定的字幕"
        case keepOtherSubtitleStreams = "流控制_启用保留其他字幕流"
        case autoMuxSRT = "流控制_自动混流SRT"
        case autoMuxASS = "流控制_自动混流ASS"
        case autoMuxSSA = "流控制_自动混流SSA"
        case autoMuxSubtitleToMovText = "流控制_自动混流的字幕转为MOVTEXT"
        case metadataOption = "流控制_元数据选项"
        case chapterOption = "流控制_章节选项"
        case attachmentOption = "流控制_附件选项"
        case computerName = "计算机名称"
        case outputLocation = "输出位置"
    }
}

private extension KeyedDecodingContainer {
    func decodeDefault<T: Decodable>(_ type: T.Type, forKey key: Key, default defaultValue: T) -> T {
        (try? decodeIfPresent(type, forKey: key)) ?? defaultValue
    }

    func decodeStringArray(forKey key: Key, default defaultValue: [String]) -> [String] {
        if let values = try? decodeIfPresent([String].self, forKey: key) {
            return values
        }
        if let value = try? decodeIfPresent(String.self, forKey: key), !value.isEmpty {
            return ShellQuoting.splitArguments(value)
        }
        return defaultValue
    }

    func decodeIntArray(forKey key: Key, default defaultValue: [Int]) -> [Int] {
        if let values = try? decodeIfPresent([Int].self, forKey: key) {
            return values
        }
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            let values = value.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            return values.isEmpty ? defaultValue : values
        }
        return defaultValue
    }
}
