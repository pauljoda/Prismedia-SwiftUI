import XCTest

@testable import PrismediaCore

#if os(iOS) || os(macOS)
    final class RequestIdentifyProviderPreferencePolicyTests: XCTestCase {
        func testEditableKindsIncludeCompatibleFallbacksAndRetainUnavailableDefaults() {
            let providers = [provider(id: "video-source", name: "Video", entityKind: EntityKind.video.rawValue)]
            let kinds = RequestIdentifyProviderPreferencePolicy.editableKinds(
                providers: providers,
                defaults: [EntityKind.book.rawValue: "removed", "future-kind": "future-provider"],
                hidesNsfw: false)

            XCTAssertTrue(kinds.contains(.movie))
            XCTAssertTrue(kinds.contains(.video))
            XCTAssertTrue(kinds.contains(.book))
            XCTAssertTrue(kinds.contains(EntityKind(rawValue: "future-kind")))
            XCTAssertFalse(kinds.contains(.tag))
            XCTAssertEqual(Set(kinds).count, kinds.count)
        }

        func testHiddenProvidersAreNotOfferedButTheirStoredDefaultsRemainEditable() {
            let hidden = provider(id: "hidden", name: "Hidden", isNsfw: true)
            XCTAssertTrue(
                RequestIdentifyProviderPreferencePolicy.editableKinds(
                    providers: [hidden], defaults: [:], hidesNsfw: true
                ).isEmpty)
            XCTAssertEqual(
                RequestIdentifyProviderPreferencePolicy.editableKinds(
                    providers: [hidden], defaults: [EntityKind.movie.rawValue: hidden.id], hidesNsfw: true), [.movie])
        }

        func testChangingOneDefaultPreservesUnknownMappingsAndAutomaticRemovesCaseVariants() {
            let original = ["MOVIE": "old", EntityKind.book.rawValue: "missing", "future-kind": "future-provider"]
            let changed = RequestIdentifyProviderPreferencePolicy.updatingDefaults(
                original, kind: .movie, providerID: "new")
            XCTAssertEqual(
                changed,
                [
                    EntityKind.movie.rawValue: "new", EntityKind.book.rawValue: "missing",
                    "future-kind": "future-provider",
                ])
            let automatic = RequestIdentifyProviderPreferencePolicy.updatingDefaults(
                changed, kind: .movie, providerID: nil)
            XCTAssertEqual(automatic, [EntityKind.book.rawValue: "missing", "future-kind": "future-provider"])
            XCTAssertEqual(original["MOVIE"], "old")
        }

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
