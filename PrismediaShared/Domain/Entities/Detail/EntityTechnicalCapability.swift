import Foundation

public struct EntityTechnicalCapability: Decodable, Hashable, Sendable {
    public let duration: String?
    public let width: Int?
    public let height: Int?
    public let frameRate: Double?
    public let bitRate: Int?
    public let sampleRate: Int?
    public let channels: Int?
    public let codec: String?
    public let container: String?
    public let format: String?

    private enum CodingKeys: String, CodingKey {
        case duration, width, height, frameRate, bitRate, sampleRate, channels, codec, container, format
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        duration = try container.decodeIfPresent(String.self, forKey: .duration)
        width = try container.decodeFlexibleIntIfPresent(forKey: .width)
        height = try container.decodeFlexibleIntIfPresent(forKey: .height)
        frameRate = try container.decodeFlexibleDoubleIfPresent(forKey: .frameRate)
        bitRate = try container.decodeFlexibleIntIfPresent(forKey: .bitRate)
        sampleRate = try container.decodeFlexibleIntIfPresent(forKey: .sampleRate)
        channels = try container.decodeFlexibleIntIfPresent(forKey: .channels)
        codec = try container.decodeIfPresent(String.self, forKey: .codec)
        self.container = try container.decodeIfPresent(String.self, forKey: .container)
        format = try container.decodeIfPresent(String.self, forKey: .format)
    }
}
