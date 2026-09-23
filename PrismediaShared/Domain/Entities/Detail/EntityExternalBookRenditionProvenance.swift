import Foundation

/// One ebook or audiobook holding managed under a canonical Book work.
public struct EntityExternalBookRenditionProvenance: Decodable, Hashable, Sendable {
    public let rendition: EntityBookRendition
    public let connectionID: UUID
    public let connectionName: String
    public let pluginID: String
    public let libraryRootID: UUID
    public let libraryLabel: String
    public let holding: EntityManagedHoldingReference
    public let request: EntityManagedRequestReference

    private enum CodingKeys: String, CodingKey {
        case rendition
        case connectionID = "connectionId"
        case connectionName
        case pluginID = "pluginId"
        case libraryRootID = "libraryRootId"
        case libraryLabel
        case holding
        case request
    }
}
