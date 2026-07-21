import Foundation

public protocol PluginAdministrationServicing: Sendable {
    func catalog() async throws -> [AdministrativePlugin]
    func stashCatalog() async throws -> [AdministrativeStashScraper]
    func install(id: String) async throws -> AdministrativePlugin
    func update(id: String) async throws -> AdministrativePlugin
    func remove(id: String) async throws
    func saveAuth(id: String, values: [String: String?]) async throws
}
