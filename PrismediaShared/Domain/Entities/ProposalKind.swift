import Foundation

/// Identify-proposal target code. Entity-backed values reuse `EntityKind`; only protocol-only
/// proposal values are declared here so adding a backend Entity kind does not create another
/// native registry to update.
public struct ProposalKind: RawRepresentable, Codable, Hashable, Sendable {
    /// Provider-only leaf episode, persisted and presented as an ordinary video Entity.
    public static let videoEpisode = Self(rawValue: "video-episode")

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Entity kind used by shared presentation and persistence-aware client behavior.
    public var entityKind: EntityKind {
        self == .videoEpisode ? .video : EntityKind(rawValue: rawValue)
    }
}
