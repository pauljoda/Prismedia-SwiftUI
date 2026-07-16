import Foundation

public protocol LibraryAdministrationServicing: Sendable {
    func roots() async throws -> [AdministrativeLibraryRoot]
    func browse(path: String?) async throws -> AdministrativeLibraryBrowseResponse
    func create(_ mutation: AdministrativeLibraryRootMutation) async throws -> AdministrativeLibraryRoot
    func update(id: UUID, mutation: AdministrativeLibraryRootMutation) async throws -> AdministrativeLibraryRoot
    func rescan(id: UUID) async throws -> Int
    func replaceAccess(id: UUID, userIDs: [UUID]) async throws
    func delete(id: UUID) async throws
}
