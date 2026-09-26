import Foundation

/// Exact connection, library, holding, and request provenance for external media.
public struct EntityExternalLibraryProvenanceCapability: Decodable, Hashable, Sendable {
    public let connectionID: UUID
    public let connectionName: String
    public let pluginID: String
    public let libraryRootID: UUID
    public let libraryLabel: String
    public let holding: EntityManagedHoldingReference?
    public let request: EntityManagedRequestReference?
    public let bookRenditions: [EntityExternalBookRenditionProvenance]?

    private enum CodingKeys: String, CodingKey {
        case connectionID = "connectionId"
        case connectionName
        case pluginID = "pluginId"
        case libraryRootID = "libraryRootId"
        case libraryLabel
        case holding
        case request
        case bookRenditions
    }
}
