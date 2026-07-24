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

        func testIdentifyProvidersAcceptSearchOnlyAndMovieVideoFallback() {
            let searchOnly = provider(
                id: "search-only",
                name: "Search Only",
                entityKind: "movie",
                actions: ["search"]
            )
            let genericVideo = provider(
                id: "video",
                name: "Generic Video",
                entityKind: "video",
                actions: []
            )

            let eligible = RequestIdentifyProviderPreferencePolicy.identifyProviders(
                [searchOnly, genericVideo],
                entityKind: "movie",
                defaultProviderIDs: ["movie": "video"],
                hidesNsfw: false
            )

            XCTAssertEqual(eligible.map(\.id), ["video", "search-only"])
        }

        func testResolvedProviderPrefersRestoredQueueProviderBeforeDefault() {
            let providers = [
                provider(id: "tmdb", name: "Default"),
                provider(id: "alpha", name: "Restored"),
            ]

            XCTAssertEqual(
                RequestIdentifyProviderPreferencePolicy.resolvedProviderID(
                    in: providers,
                    restoredProviderID: "ALPHA",
                    currentProviderID: nil
                ),
                "alpha"
            )
        }

        private func provider(
            id: String,
            name: String,
            isNsfw: Bool = false,
            entityKind: String = "movie",
            actions: [String] = ["search", "lookup-id"]
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
                        entityKind: entityKind,
                        actions: actions,
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
