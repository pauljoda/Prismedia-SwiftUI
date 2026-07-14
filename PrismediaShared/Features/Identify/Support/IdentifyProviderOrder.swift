import Foundation

#if os(iOS) || os(macOS)
    struct IdentifyProviderOrder {
        static func ids(
            selected: String?,
            providers: [AdministrativePlugin],
            kind: EntityKind,
            hidesNsfw: Bool
        ) -> [String] {
            let eligible = providers.filter { provider in
                provider.installed && provider.enabled && provider.missingAuthKeys.isEmpty
                    && (!hidesNsfw || !provider.isNsfw)
                    && provider.supports.contains {
                        $0.entityKind == kind.rawValue && IdentifyProviderPolicy.supportsIdentify($0)
                    }
            }.map(\.id)
            guard let selected, eligible.contains(selected) else { return eligible }
            return [selected] + eligible.filter { $0 != selected }
        }
    }
#endif
