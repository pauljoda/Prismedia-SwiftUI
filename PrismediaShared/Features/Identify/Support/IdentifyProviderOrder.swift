import Foundation

#if os(iOS) || os(macOS)
    struct IdentifyProviderOrder {
        static func ids(
            selected: String?,
            providers: [AdministrativePlugin],
            kind: EntityKind,
            hidesNsfw: Bool,
            defaultProviderIDs: [String: String] = [:]
        ) -> [String] {
            let eligible = RequestIdentifyProviderPreferencePolicy.identifyProviders(
                providers,
                entityKind: kind.rawValue,
                defaultProviderIDs: defaultProviderIDs,
                hidesNsfw: hidesNsfw
            ).map(\.id)
            guard
                let selectedID = eligible.first(where: {
                    $0.caseInsensitiveCompare(selected ?? "") == .orderedSame
                })
            else {
                return eligible
            }
            return [selectedID] + eligible.filter { $0 != selectedID }
        }
    }
#endif
