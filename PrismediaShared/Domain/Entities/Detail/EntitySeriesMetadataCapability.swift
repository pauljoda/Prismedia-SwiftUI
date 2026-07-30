import Foundation

/// Series-only publication status.
public struct EntitySeriesMetadataCapability: Decodable, Hashable, Sendable {
    public let status: String?
}
