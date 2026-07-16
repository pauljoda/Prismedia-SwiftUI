import Foundation

public struct AdministrativeLibraryBrowseResponse: Decodable, Hashable, Sendable {
    public let path: String
    public let parentPath: String?
    public let directories: [AdministrativeLibraryBrowseEntry]
}
