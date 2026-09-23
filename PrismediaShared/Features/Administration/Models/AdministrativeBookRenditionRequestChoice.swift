import Foundation

/// A format and its optional destination in one reviewed Book request.
public struct AdministrativeBookRenditionRequestChoice: Encodable, Hashable, Sendable {
    public let rendition: String
    public let targetLibraryRootID: UUID?
    public let profileID: UUID?

    public init(rendition: String, targetLibraryRootID: UUID?, profileID: UUID?) {
        self.rendition = rendition
        self.targetLibraryRootID = targetLibraryRootID
        self.profileID = profileID
    }

    private enum CodingKeys: String, CodingKey {
        case rendition
        case targetLibraryRootID = "targetLibraryRootId"
        case profileID = "profileId"
    }
}
