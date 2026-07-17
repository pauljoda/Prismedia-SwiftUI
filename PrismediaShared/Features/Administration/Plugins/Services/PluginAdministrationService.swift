import Foundation

public struct PluginAdministrationService: PluginAdministrationServicing {
    private let client: PrismediaAPIClient

    public init(client: PrismediaAPIClient) { self.client = client }

    public func catalog() async throws -> [AdministrativePlugin] {
        try await client.listAdministrativePluginCatalog()
    }

    public func stashCatalog() async throws -> [AdministrativeStashScraper] {
        try await client.listAdministrativeStashScrapers()
    }

    public func install(id: String) async throws -> AdministrativePlugin {
        try await client.installAdministrativePlugin(id: id)
    }

    public func update(id: String) async throws -> AdministrativePlugin {
        try await client.updateAdministrativePlugin(id: id)
    }

    public func remove(id: String) async throws {
        try await client.removeAdministrativePlugin(id: id)
    }

    public func saveAuth(id: String, values: [String: String?]) async throws {
        try await client.saveAdministrativePluginAuth(id: id, values: values)
    }
}
