import Foundation

public enum OutputPathBuilder {
    public static func build(inputFile: String, preset: PresetData, customDirectory: String = "") -> String {
        guard !preset.omitOutputFileArgument else { return "" }
        let inputURL = URL(fileURLWithPath: inputFile)
        let directory: String
        if !customDirectory.isEmpty {
            directory = customDirectory
        } else if !preset.outputLocation.isEmpty {
            directory = preset.outputLocation
        } else {
            directory = inputURL.deletingLastPathComponent().path
        }

        var ext = preset.outputContainer.isEmpty ? inputURL.pathExtension : preset.outputContainer
        if ext.hasPrefix(".") {
            ext.removeFirst()
        }
        if ext.isEmpty {
            ext = "mp4"
        }

        let baseName = inputURL.deletingPathExtension().lastPathComponent
        var fileName = preset.outputNamePrefix
        fileName += preset.outputNameReplacement.isEmpty ? baseName : preset.outputNameReplacement
        fileName += preset.outputNameSuffix

        if preset.useAutoNaming {
            switch preset.autoNamingOption {
            case .timestamp:
                fileName += "_" + timestamp()
            case .incrementNumber:
                fileName += "~1"
            case .append3FUI:
                fileName += "_3fui"
            case .encoderAndQuality:
                if !preset.videoEncoder.isEmpty { fileName += ".\(preset.videoEncoder)" }
                if !preset.videoPreset.isEmpty { fileName += ".\(preset.videoPreset)" }
                if !preset.qualityArgumentName.isEmpty, !preset.qualityValue.isEmpty {
                    fileName += ".\(preset.qualityArgumentName.replacingOccurrences(of: "-", with: ""))\(preset.qualityValue)"
                }
                if !preset.bitrateBase.isEmpty { fileName += ".\(preset.bitrateBase)" }
                if !preset.bitrateMin.isEmpty { fileName += ".L\(preset.bitrateMin)" }
                if !preset.bitrateMax.isEmpty { fileName += ".H\(preset.bitrateMax)" }
                if !preset.bitrateBuffer.isEmpty { fileName += ".BF\(preset.bitrateBuffer)" }
            case .random8Digits:
                fileName += "_" + randomString(length: 8, digits: true, letters: false)
            case .random8Letters:
                fileName += "_" + randomString(length: 8, digits: false, letters: true)
            case .random8Alphanumeric:
                fileName += "_" + randomString(length: 8, digits: true, letters: true)
            case .random16Digits:
                fileName += "_" + randomString(length: 16, digits: true, letters: false)
            case .random16Letters:
                fileName += "_" + randomString(length: 16, digits: false, letters: true)
            case .random16Alphanumeric:
                fileName += "_" + randomString(length: 16, digits: true, letters: true)
            }
        }

        if fileName.isEmpty {
            fileName = baseName
        }

        let output = URL(fileURLWithPath: directory).appendingPathComponent(fileName).appendingPathExtension(ext)
        if output.standardizedFileURL.path == inputURL.standardizedFileURL.path {
            return output
                .deletingLastPathComponent()
                .appendingPathComponent(fileName + "_3fui")
                .appendingPathExtension(ext)
                .path
        }
        return output.path
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd-HH.mm.ss"
        return formatter.string(from: Date())
    }

    private static func randomString(length: Int, digits: Bool, letters: Bool) -> String {
        var alphabet = ""
        if digits { alphabet += "0123456789" }
        if letters { alphabet += "abcdefghijklmnopqrstuvwxyz" }
        if alphabet.isEmpty { alphabet = "0123456789abcdefghijklmnopqrstuvwxyz" }
        return String((0..<length).compactMap { _ in alphabet.randomElement() })
    }
}
