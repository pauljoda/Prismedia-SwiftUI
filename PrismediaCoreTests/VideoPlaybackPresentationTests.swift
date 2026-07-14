import CoreMedia
import XCTest

@testable import PrismediaCore

final class VideoPlaybackPresentationTests: XCTestCase {
    func testClockTimeStaysCompactForShortAndFeatureLengthVideo() {
        XCTAssertEqual(VideoPlaybackPresentation.clockTime(42), "0:42")
        XCTAssertEqual(VideoPlaybackPresentation.clockTime(5_752), "1:35:52")
        XCTAssertEqual(VideoPlaybackPresentation.clockTime(.nan), "0:00")
    }

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

final class VideoFilmstripLayoutTests: XCTestCase {
    private let frames = (0..<100).map { index in
        TrickplayPlaylist.Frame(
            startTime: Double(index) * 10,
            imageURL: URL(string: "https://media.example.test/\(index / 25).jpg")!,
            crop: .init(x: 0, y: 0, width: 320, height: 180),
            imageWidth: 1_600,
            imageHeight: 900
        )
    }

    func testContinuousIndexInterpolatesBetweenFrameUpdates() {
        XCTAssertEqual(VideoFilmstripLayout.continuousIndex(at: 15, frames: frames), 1.5)
        XCTAssertEqual(VideoFilmstripLayout.continuousIndex(at: 995, frames: frames, duration: 1_000), 99.5)
    }

    func testVisibleWindowStaysBoundedAroundThePlayhead() {
        let indexes = VideoFilmstripLayout.visibleIndexes(at: 50.4, frameCount: frames.count, radius: 8)

        XCTAssertEqual(indexes, Array(42...58))
        XCTAssertEqual(indexes.count, 17)
    }

    func testInitialSpriteURLsAreUniqueAndBounded() {
        let urls = VideoFilmstripLayout.spriteURLsToPrewarm(at: 24, frames: frames, radius: 8)

        XCTAssertEqual(
            urls,
            [
                URL(string: "https://media.example.test/0.jpg")!,
                URL(string: "https://media.example.test/1.jpg")!,
            ])
    }
}
