import Foundation

/// Per-person relationship annotations such as roles and character names.
public struct EntityCreditsCapability: Decodable, Hashable, Sendable {
    public let items: [EntityCreditMetadata]
}
