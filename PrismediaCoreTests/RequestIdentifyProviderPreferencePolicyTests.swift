import XCTest

@testable import PrismediaCore

#if os(iOS) || os(macOS)
    final class RequestIdentifyProviderPreferencePolicyTests: XCTestCase {
        func testConfiguredProviderIsFirstAndMatchedCaseInsensitively() {
            let providers = [
                provider(id: "alpha", name: "Alpha"),
                provider(id: "TMDB", name: "Zulu"),
            ]

            let ordered = RequestIdentifyProviderPreferencePolicy.eligibleProviders(
                providers,
                entityKind: "movie",
                defaultProviderIDs: ["movie": "tmdb"],
                hidesNsfw: false
            )

            XCTAssertEqual(ordered.map(\.id), ["TMDB", "alpha"])
        }

        func testStaleOrHiddenDefaultFallsBackToAlphabeticalEligibleProvider() {
            let providers = [
                provider(id: "zulu", name: "Zulu"),
                provider(id: "adult", name: "Adult", isNsfw: true),
                provider(id: "alpha", name: "Alpha"),
            ]

            let stale = RequestIdentifyProviderPreferencePolicy.eligibleProviders(
                providers,
                entityKind: "movie",
                defaultProviderIDs: ["movie": "removed"],
                hidesNsfw: false
            )
            let hidden = RequestIdentifyProviderPreferencePolicy.eligibleProviders(
                providers,
                entityKind: "movie",
                defaultProviderIDs: ["movie": "adult"],
                hidesNsfw: true
            )

            XCTAssertEqual(stale.map(\.id), ["adult", "alpha", "zulu"])
            XCTAssertEqual(hidden.map(\.id), ["alpha", "zulu"])
        }

        private func provider(
            id: String,
            name: String,
            isNsfw: Bool = false
        ) -> AdministrativePlugin {
            AdministrativePlugin(
                id: id,
                name: name,
                version: "1",
                installed: true,
                enabled: true,
                isNsfw: isNsfw,
                supports: [
                    AdministrativePluginSupport(
                        entityKind: "movie",
                        actions: ["search", "lookup-id"],
                        search: AdministrativePluginSearchDefinition(fields: [
                            AdministrativePluginSearchField(
                                key: "title",
                                label: "Title",
                                type: "text",
                                required: true,
                                placeholder: nil,
                                help: nil
                            )
                        ])
                    )
                ],
                missingAuthKeys: [],
                updateAvailable: false,
                availableVersion: nil
            )
        }
    }
#endif
