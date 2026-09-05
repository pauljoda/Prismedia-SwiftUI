import Foundation
import Observation

/// Owns the current server-confirmed provider while its management sheet is open.
@Observable @MainActor
final class PluginManagementSession {
    private(set) var plugin: AdministrativePlugin
    private(set) var isWorking = false
    private(set) var refreshError: String?
    var errorMessage: String?
    private let service: any PluginAdministrationServicing

    init(plugin: AdministrativePlugin, service: any PluginAdministrationServicing) {
        self.plugin = plugin
        self.service = service
    }

    @discardableResult
    func install() async -> Bool {
        await mutate { try await PluginAdministrationUseCase(service: self.service).install(id: self.plugin.id) }
    }

    @discardableResult
    func update() async -> Bool {
        await mutate { try await PluginAdministrationUseCase(service: self.service).update(id: self.plugin.id) }
    }

    func remove() async -> Bool {
        await mutate {
            try await PluginAdministrationUseCase(service: self.service).remove(id: self.plugin.id)
            return nil
        }
    }

    func refresh() async {
        guard !isWorking else { return }
        isWorking = true
        refreshError = nil
        defer { isWorking = false }
        do {
            let catalog = try await service.catalog()
            guard let current = catalog.first(where: { $0.id == plugin.id }) else {
                refreshError = "This provider is no longer in the catalog. Close this page and refresh Plugins."
                return
            }
            plugin = current
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            refreshError = error.localizedDescription
        }
    }

    private func mutate(_ operation: @MainActor () async throws -> AdministrativePlugin?) async -> Bool {
        guard !isWorking, !Task.isCancelled else { return false }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            if let updated = try await operation() { plugin = updated }
            refreshError = nil
            return true
        } catch is CancellationError {
            return false
        } catch let error as URLError where error.code == .cancelled {
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
