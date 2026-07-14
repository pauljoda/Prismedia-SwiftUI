import XCTest

@testable import PrismediaCore

final class PluginSearchPresentationStateTests: XCTestCase {
    func testPresentationStateDistinguishesEverySearchPhase() {
        XCTAssertEqual(
            PluginSearchPresentationState.resolve(
                hasProvider: false,
                isSearching: false,
                hasSearched: false,
                candidateCount: 0,
                errorMessage: nil
            ),
            .noProvider
        )
        XCTAssertEqual(
            PluginSearchPresentationState.resolve(
                hasProvider: true,
                isSearching: false,
                hasSearched: false,
                candidateCount: 0,
                errorMessage: nil
            ),
            .preSearch
        )
        XCTAssertEqual(
            PluginSearchPresentationState.resolve(
                hasProvider: true,
                isSearching: true,
                hasSearched: true,
                candidateCount: 2,
                errorMessage: nil
            ),
            .searching
        )
        XCTAssertEqual(
            PluginSearchPresentationState.resolve(
                hasProvider: true,
                isSearching: false,
                hasSearched: true,
                candidateCount: 0,
                errorMessage: nil
            ),
            .noResults
        )
        XCTAssertEqual(
            PluginSearchPresentationState.resolve(
                hasProvider: true,
                isSearching: false,
                hasSearched: true,
                candidateCount: 2,
                errorMessage: nil
            ),
            .results(count: 2)
        )
    }

    func testErrorTakesPrecedenceOverOtherPresentationState() {
        XCTAssertEqual(
            PluginSearchPresentationState.resolve(
                hasProvider: false,
                isSearching: true,
                hasSearched: true,
                candidateCount: 2,
                errorMessage: "Provider unavailable"
            ),
            .error(message: "Provider unavailable")
        )
    }
}
