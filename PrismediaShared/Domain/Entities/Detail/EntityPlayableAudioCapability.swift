import Foundation

/// Generic queue and transport semantics for an Entity that can supply playable audio items.
public struct EntityPlayableAudioCapability: Decodable, Hashable, Sendable {
    public let itemKind: EntityKind
    public let preservesQueueOrder: Bool
    public let supportsPlaybackRate: Bool
}
