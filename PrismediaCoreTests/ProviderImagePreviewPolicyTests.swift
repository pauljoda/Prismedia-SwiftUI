import XCTest

@testable import PrismediaCore

final class ProviderImagePreviewPolicyTests: XCTestCase {
    func testRewritesTMDBPosterToPreviewSize() {
        XCTAssertEqual(
            ProviderImagePreviewPolicy.previewURL(
                for: "https://image.tmdb.org/t/p/original/gDzOcq0pfeCeqMBwKIJlSmQpjkZ.jpg",
                imageKind: "poster"
            ),
            "https://image.tmdb.org/t/p/w342/gDzOcq0pfeCeqMBwKIJlSmQpjkZ.jpg"
        )
    }

    func testRewritesTMDBBackdropWider() {
        XCTAssertEqual(
            ProviderImagePreviewPolicy.previewURL(
                for: "https://image.tmdb.org/t/p/original/abc.jpg", imageKind: "backdrop"),
            "https://image.tmdb.org/t/p/w780/abc.jpg"
        )
    }

    func testRewritesPersonTargetsToProfileSize() {
        XCTAssertEqual(
            ProviderImagePreviewPolicy.previewURL(
                for: "https://image.tmdb.org/t/p/original/abc.jpg",
                imageKind: "poster",
                targetKind: "person"
            ),
            "https://image.tmdb.org/t/p/w185/abc.jpg"
        )
    }

    func testRewritesGoogleUserContentSizeHints() {
        XCTAssertEqual(
            ProviderImagePreviewPolicy.previewURL(
                for: "https://yt3.googleusercontent.com/x/photo=s1000-c-k", imageKind: "cover"),
            "https://yt3.googleusercontent.com/x/photo=s360-c-k"
        )
        XCTAssertEqual(
            ProviderImagePreviewPolicy.previewURL(
                for: "https://lh3.googleusercontent.com/x=w1000-h800-p", imageKind: "backdrop"),
            "https://lh3.googleusercontent.com/x=w720-h720-p"
        )
    }

    func testLeavesOtherURLsUntouched() {
        XCTAssertEqual(
            ProviderImagePreviewPolicy.previewURL(for: "/assets/covers/abc.jpg"),
            "/assets/covers/abc.jpg"
        )
        XCTAssertEqual(
            ProviderImagePreviewPolicy.previewURL(for: "https://covers.openlibrary.org/b/id/1-L.jpg"),
            "https://covers.openlibrary.org/b/id/1-L.jpg"
        )
        XCTAssertNil(ProviderImagePreviewPolicy.previewURL(for: nil))
    }
}
