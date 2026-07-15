import Foundation

public enum AdministrativePluginVisibilityPolicy {
    public static func visiblePlugins(
        _ plugins: [AdministrativePlugin],
        hidesNsfw: Bool
    ) -> [AdministrativePlugin] {
        guard hidesNsfw else { return plugins }
        return plugins.filter { !$0.isNsfw }
    }
}
