import Foundation

@MainActor
public struct PluginAdministrationUseCase {
    private let service: any PluginAdministrationServicing

    public init(service: any PluginAdministrationServicing) { self.service = service }

    public func install(id: String) async throws -> AdministrativePlugin {
        let plugin = try await service.install(id: id)
        notifyProviderConsumers()
        return plugin
    }

    public func update(id: String) async throws -> AdministrativePlugin {
        let plugin = try await service.update(id: id)
        notifyProviderConsumers()
        return plugin
    }

    public func remove(id: String) async throws {
        try await service.remove(id: id)
        notifyProviderConsumers()
    }

    public func saveAuth(id: String, replacements: [String: String], clearedKeys: Set<String>) async throws {
        var values = replacements.reduce(into: [String: String?]()) { result, pair in
            let trimmed = pair.value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { result[pair.key] = trimmed }
        }
        for key in clearedKeys { values[key] = .some(nil) }
        guard !values.isEmpty else { return }
        try await service.saveAuth(id: id, values: values)
        notifyProviderConsumers()
    }

    private func notifyProviderConsumers() {
        NotificationCenter.default.post(name: AdministrativeProviderCatalogEvent.didChange, object: nil)
    }
}
