import Foundation

/// Tag behavior used by automated metadata enrichment.
public struct EntityTagPolicyCapability: Decodable, Hashable, Sendable {
    public let ignoreAutoTag: Bool
}
