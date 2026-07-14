import XCTest

@testable import PrismediaCore

#if os(iOS) || os(macOS)
    final class IdentifyProviderOrderTests: XCTestCase {
        func testSelectedProviderLeadsThenRemainingEligibleProvidersKeepServerOrder() {
            let ordered = IdentifyProviderOrder.ids(
                selected: "fanart",
                providers: [
                    provider(id: "tmdb", kind: "movie"),
                    provider(id: "fanart", kind: "movie"),
                    provider(id: "books", kind: "book"),
                    provider(id: "disabled", kind: "movie", enabled: false),
                ],
                kind: .movie,
                hidesNsfw: true
            )

            XCTAssertEqual(ordered, ["fanart", "tmdb"])
        }

        private func provider(id: String, kind: String, enabled: Bool = true) -> AdministrativePlugin {
            AdministrativePlugin(
                id: id, name: id, version: "1", installed: true, enabled: enabled, isNsfw: false,
                supports: [.init(entityKind: kind, actions: ["identify"])], missingAuthKeys: [],
                updateAvailable: false, availableVersion: nil)
        }
    }
#endif
