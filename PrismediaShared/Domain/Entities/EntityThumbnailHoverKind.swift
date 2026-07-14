import Foundation

public enum EntityThumbnailHoverKind: Decodable, Hashable, Sendable {
    case none
    case sprite
    case imageSequence
    case trickplay
    case unknown(String)

    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = Self(rawValue: value)
    }

    public init(rawValue: String) {
        switch rawValue {
        case "none": self = .none
        case "sprite": self = .sprite
        case "image-sequence": self = .imageSequence
        case "trickplay": self = .trickplay
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .none: "none"
        case .sprite: "sprite"
        case .imageSequence: "image-sequence"
        case .trickplay: "trickplay"
        case .unknown(let value): value
        }
    }
}
