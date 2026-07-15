import XCTest

@testable import PrismediaCore

final class AdministrativePluginVisibilityPolicyTests: XCTestCase {
    func testVisiblePluginsExcludesNsfwPluginsOnlyWhenContentIsHidden() {
        let sfwPlugin = plugin(id: "tmdb", isNsfw: false)
        let nsfwPlugin = plugin(id: "adult-provider", isNsfw: true)
        let plugins = [sfwPlugin, nsfwPlugin]

        XCTAssertEqual(
            AdministrativePluginVisibilityPolicy.visiblePlugins(plugins, hidesNsfw: true),
            [sfwPlugin]
        )
        XCTAssertEqual(
            AdministrativePluginVisibilityPolicy.visiblePlugins(plugins, hidesNsfw: false),
            plugins
        )
    }

    private func plugin(id: String, isNsfw: Bool) -> AdministrativePlugin {
        AdministrativePlugin(
            id: id,
            name: id,
            version: "1.0",
            installed: true,
            enabled: true,
            isNsfw: isNsfw,
            supports: [],
            missingAuthKeys: [],
            updateAvailable: false,
            availableVersion: nil
        )
    }
}
