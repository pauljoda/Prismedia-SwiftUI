import XCTest

@testable import PrismediaCore

final class TVEpisodeDescriptionPresentationTests: XCTestCase {
    func testFocusedEpisodeSummaryReplacesSeriesDescriptionImmediately() {
        let episode = EntityThumbnail(
            id: UUID(),
            kind: .video,
            title: "Episode",
            summary: "Focused episode summary"
        )

        XCTAssertEqual(
            TVEpisodeDescriptionPresentation.text(
                episode: episode,
                seriesDescription: "Series description"
            ),
            "Focused episode summary"
        )
    }

    func testSeriesDescriptionIsFallbackBeforeEpisodeFocus() {
        XCTAssertEqual(
            TVEpisodeDescriptionPresentation.text(
                episode: nil,
                seriesDescription: "Series description"
            ),
            "Series description"
        )
    }

    func testLongCopyKeepsDisclosureAvailableBeforeGeometrySettles() {
        XCTAssertFalse(
            TVEpisodeDescriptionPresentation.likelyRequiresDisclosure(
                "A short episode summary."
            )
        )
        XCTAssertTrue(
            TVEpisodeDescriptionPresentation.likelyRequiresDisclosure(
                String(repeating: "A detailed episode summary. ", count: 8)
            )
        )
    }
}
