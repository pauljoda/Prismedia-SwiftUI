import Foundation

struct AdministrativeUserLibraryAccessRequest: Encodable, Sendable {
    let libraryRootIDs: [UUID]

    private enum CodingKeys: String, CodingKey {
        case libraryRootIDs = "libraryRootIds"
    }
}
