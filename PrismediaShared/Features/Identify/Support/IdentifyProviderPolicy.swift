import Foundation

#if os(iOS) || os(macOS)
    struct IdentifyProviderPolicy {
        static func supportsIdentify(_ support: AdministrativePluginSupport) -> Bool {
            support.actions.contains("identify") || support.actions.contains("lookup-id")
        }
    }
#endif
