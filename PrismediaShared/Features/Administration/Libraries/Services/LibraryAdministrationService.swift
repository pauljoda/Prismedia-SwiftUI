import Foundation

public struct LibraryAdministrationService: LibraryAdministrationServicing {
    private let client: PrismediaAPIClient

    public init(client: PrismediaAPIClient) { self.client = client }

    public func roots() async throws -> [AdministrativeLibraryRoot] {
        try await client.listAdministrativeLibraryRoots()
    }

    public func browse(path: String?) async throws -> AdministrativeLibraryBrowseResponse {
        try await client.browseAdministrativeLibraryPath(path)
    }

    public func create(_ mutation: AdministrativeLibraryRootMutation) async throws -> AdministrativeLibraryRoot {
        try await client.createAdministrativeLibraryRoot(mutation)
    }

    public func update(id: UUID, mutation: AdministrativeLibraryRootMutation) async throws
        -> AdministrativeLibraryRoot
    {
        try await client.updateAdministrativeLibraryRoot(id: id, mutation: mutation)
    }

    public func rescan(id: UUID) async throws -> Int {
        try await client.rescanAdministrativeFiles(rootID: id, path: nil).scansQueued
    }

    public func replaceAccess(id: UUID, userIDs: [UUID]) async throws {
        try await client.replaceAdministrativeLibraryAccess(rootID: id, userIDs: userIDs)
    }

    public func delete(id: UUID) async throws { try await client.deleteAdministrativeLibraryRoot(id: id) }
}
