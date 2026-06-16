import Foundation

public enum PresetIOService {
    public static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }()

    public static let decoder = JSONDecoder()

    public static func load(from url: URL) throws -> PresetData {
        let data = try Data(contentsOf: url)
        return try decoder.decode(PresetData.self, from: data)
    }

    public static func save(_ preset: PresetData, to url: URL) throws {
        let data = try encoder.encode(preset)
        try data.write(to: url, options: [.atomic])
    }
}
