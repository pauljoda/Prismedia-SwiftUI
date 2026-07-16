import Foundation

public struct AdministrativeLibraryBrowseEntry: Decodable, Identifiable, Hashable, Sendable {
    public let name: String
    public let path: String
    public var id: String { path }
}
