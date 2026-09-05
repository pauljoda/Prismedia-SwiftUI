import Foundation

@testable import PrismediaCore

actor PluginManagementServiceStub: PluginAdministrationServicing {
    private var response: AdministrativePlugin
    private var failure: URLError?
    private var savedValues: [String: String?] = [:]

    init(response: AdministrativePlugin) { self.response = response }
    func setFailure(_ failure: URLError?) { self.failure = failure }
    func authValues() -> [String: String?] { savedValues }
    func catalog() async throws -> [AdministrativePlugin] {
        if let failure { throw failure }
        return [response]
    }
    func stashCatalog() async throws -> [AdministrativeStashScraper] { [] }
    func install(id: String) async throws -> AdministrativePlugin {
        if let failure { throw failure }
        return response
    }
    func update(id: String) async throws -> AdministrativePlugin { try await install(id: id) }
    func remove(id: String) async throws {
        if let failure { throw failure }
    }
    func saveAuth(id: String, values: [String: String?]) async throws {
        if let failure { throw failure }
        savedValues = values
    }
}
