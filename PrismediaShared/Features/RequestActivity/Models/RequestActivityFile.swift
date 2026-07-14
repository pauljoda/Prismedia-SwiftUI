import Foundation

public struct RequestActivityFile: Decodable, Equatable, Sendable {
    public let name: String
    public let sizeBytes: Int64
    public let progress: Double

    private enum CodingKeys: String, CodingKey {
        case name
        case sizeBytes
        case progress
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        sizeBytes = try RequestActivityDecoding.integer64(from: container, forKey: .sizeBytes)
        progress = try RequestActivityDecoding.double(from: container, forKey: .progress)
    }
}
