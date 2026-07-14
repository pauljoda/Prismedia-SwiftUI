import XCTest

@testable import PrismediaCore

final class EntityImageViewerPagePresentationTests: XCTestCase {
    func testThumbnailArtworkRemainsVisibleWhenDetailLoadingFails() {
        let presentation = EntityImageViewerPagePresentation.resolve(
            projection: nil,
            isLoading: false,
            errorMessage: "The detail request failed",
            fallbackArtworkPath: "/assets/images/fallback.jpg"
        )

        XCTAssertEqual(presentation, .fallback(path: "/assets/images/fallback.jpg"))
    }

    func testMissingArtworkShowsTheLoadingStateUntilTheRequestStarts() {
        let presentation = EntityImageViewerPagePresentation.resolve(
            projection: nil,
            isLoading: false,
            errorMessage: nil,
            fallbackArtworkPath: nil
        )

        XCTAssertEqual(presentation, .loading(fallbackPath: nil))
    }

    func testLoadingKeepsFallbackArtworkBehindProgress() {
        let presentation = EntityImageViewerPagePresentation.resolve(
            projection: nil,
            isLoading: true,
            errorMessage: nil,
            fallbackArtworkPath: "/assets/images/fallback.jpg"
        )

        XCTAssertEqual(
            presentation,
            .loading(fallbackPath: "/assets/images/fallback.jpg")
        )
    }

    func testFailureWithoutFallbackShowsTheError() {
        let presentation = EntityImageViewerPagePresentation.resolve(
            projection: nil,
            isLoading: false,
            errorMessage: "Source unavailable",
            fallbackArtworkPath: nil
        )

        XCTAssertEqual(presentation, .failure(message: "Source unavailable"))
    }
}
