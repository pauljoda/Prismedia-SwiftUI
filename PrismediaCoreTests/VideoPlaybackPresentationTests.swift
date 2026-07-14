import CoreMedia
import XCTest

@testable import PrismediaCore

final class VideoPlaybackPresentationTests: XCTestCase {
    func testBufferedEndUsesTheFurthestLoadedRangeAndClampsToDuration() {
        let ranges = [
            CMTimeRange(
                start: .init(seconds: 0, preferredTimescale: 600), duration: .init(seconds: 20, preferredTimescale: 600)
            ),
            CMTimeRange(
                start: .init(seconds: 40, preferredTimescale: 600),
                duration: .init(seconds: 80, preferredTimescale: 600)),
        ]

        XCTAssertEqual(VideoPlaybackPresentation.bufferedEnd(ranges: ranges, duration: 90), 90)
    }
}
