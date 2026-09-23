import Foundation

/// Connection-scoped remote identity pin for a managed holding.
public struct EntityManagedItemInput: Decodable, Hashable, Sendable {
    public let entityKind: EntityKind
    public let remoteID: String
    public let expectedExternalIDs: [String: String]
    public let bookRendition: EntityBookRendition?

    private enum CodingKeys: String, CodingKey {
        case entityKind
        case remoteID = "remoteId"
        case expectedExternalIDs = "expectedExternalIds"
        case bookRendition
    }
}
