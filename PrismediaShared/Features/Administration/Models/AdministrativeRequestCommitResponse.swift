import Foundation

public struct AdministrativeRequestCommitResponse: Decodable, Hashable, Sendable {
    public let containerEntityID: UUID?
    public let items: [AdministrativeRequestCommitItem]
    public let bookRenditions: [AdministrativeBookRenditionCommitResult]?

    public init(
        containerEntityID: UUID?,
        items: [AdministrativeRequestCommitItem],
        bookRenditions: [AdministrativeBookRenditionCommitResult]? = nil
    ) {
        self.containerEntityID = containerEntityID
        self.items = items
        self.bookRenditions = bookRenditions
    }

    enum CodingKeys: String, CodingKey {
        case containerEntityID = "containerEntityId"
        case items
        case bookRenditions
    }
}
