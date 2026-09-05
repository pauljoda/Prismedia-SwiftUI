import Foundation
import Observation

/// Loads the settings catalog independently from supporting cache and provider data.
@MainActor @Observable
final class AdministrativeSettingsLoadSession {
    private(set) var catalog = AdministrativeCollectionLoadState<AdministrativeSettingsCatalog>()
    private(set) var cache = AdministrativeCollectionLoadState<AdministrativeTranscodeCacheStatus>()
    private(set) var plugins = AdministrativeCollectionLoadState<AdministrativePlugin>()

    var isLoading: Bool { catalog.isLoading || cache.isLoading || plugins.isLoading }

    func load(service: any AdministrationServicing) async {
        async let settings: () = loadCatalog(service: service)
        async let storage: () = loadCache(service: service)
        async let providers: () = loadPlugins(service: service)
        _ = await (settings, storage, providers)
    }

    func loadCatalog(service: any AdministrationServicing) async {
        let request = catalog.begin()
        do {
            let loaded = try await service.settings()
            catalog.succeed([loaded], request: request, isCancelled: Task.isCancelled)
        } catch {
            catalog.fail(error, request: request, isCancelled: Task.isCancelled)
        }
    }

    func loadCache(service: any AdministrationServicing) async {
        let request = cache.begin()
        do {
            let loaded = try await service.transcodeCacheStatus()
            cache.succeed([loaded], request: request, isCancelled: Task.isCancelled)
        } catch {
            cache.fail(error, request: request, isCancelled: Task.isCancelled)
        }
    }

    func loadPlugins(service: any AdministrationServicing) async {
        let request = plugins.begin()
        do {
            let loaded = try await service.plugins()
            plugins.succeed(loaded, request: request, isCancelled: Task.isCancelled)
        } catch {
            plugins.fail(error, request: request, isCancelled: Task.isCancelled)
        }
    }

    /// Records the server's acknowledged setting and supersedes any older catalog read.
    func accept(_ setting: AdministrativeSetting) {
        guard let current = catalog.items.first else { return }
        let updated = AdministrativeSettingsCatalog(
            groups: current.groups.map { group in
                AdministrativeSettingsGroup(
                    key: group.key, label: group.label, description: group.description, order: group.order,
                    settings: group.settings.map { $0.key == setting.key ? setting : $0 })
            })
        let request = catalog.begin()
        catalog.succeed([updated], request: request)
    }

    /// Records acknowledged cache maintenance without requiring a second read to succeed.
    func accept(_ status: AdministrativeTranscodeCacheStatus) {
        let request = cache.begin()
        cache.succeed([status], request: request)
    }
}
