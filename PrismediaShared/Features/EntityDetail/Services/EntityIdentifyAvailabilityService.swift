import Foundation

#if os(iOS) || os(macOS)
    struct EntityIdentifyAvailabilityService: Sendable {
        let administration: any AdministrationServicing
        let hidesNsfw: Bool

        func load(
            entityID: UUID,
            kind: EntityKind
        ) async -> EntityIdentifyAvailability {
            async let queueItem = optionalQueueItem(entityID: entityID)
            async let providers = (try? administration.identifyProviders(kind: kind.rawValue)) ?? []

            let (item, loadedProviders) = await (queueItem, providers)
            if let item, isActive(item) {
                return .queued(item: item, providers: loadedProviders)
            }
            if hasReadyProvider(in: loadedProviders, kind: kind) {
                return .ready(providers: loadedProviders)
            }
            return .unavailable
        }

        private func optionalQueueItem(
            entityID: UUID
        ) async -> AdministrativeIdentifyQueueItem? {
            do {
                return try await administration.identifyQueueItem(entityID: entityID)
            } catch PrismediaAPIError.httpStatus(404, _) {
                return nil
            } catch {
                return nil
            }
        }

        private func isActive(_ item: AdministrativeIdentifyQueueItem) -> Bool {
            let state = IdentifyQueueState(rawServerValue: item.state)
            return state != .done && state != .deleted
        }

        private func hasReadyProvider(
            in providers: [AdministrativePlugin],
            kind: EntityKind
        ) -> Bool {
            providers.contains { provider in
                provider.installed
                    && provider.enabled
                    && provider.missingAuthKeys.isEmpty
                    && (!hidesNsfw || !provider.isNsfw)
                    && provider.supports.contains { support in
                        support.entityKind.caseInsensitiveCompare(kind.rawValue) == .orderedSame
                            && IdentifyProviderPolicy.supportsIdentify(support)
                    }
            }
        }
    }
#endif
