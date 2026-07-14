import XCTest

@testable import PrismediaCore

final class TVEpisodePreviewFrameSamplerTests: XCTestCase {
    func testSamplesFourFramesOnlyFromTwentyThroughSeventyPercent() {
        let frames = (0..<100).map(frame)

        let sampled = TVEpisodePreviewFrameSampler.sample(frames, limit: 4)

        XCTAssertEqual(sampled.map(\.startTime), [20, 36, 53, 69])
    }

    func testShortPlaylistStillExcludesOpeningAndEndingFrames() {
        let frames = (0..<10).map(frame)

        let sampled = TVEpisodePreviewFrameSampler.sample(frames, limit: 5)

        XCTAssertEqual(sampled.map(\.startTime), [2, 3, 4, 5, 6])
    }

    func testEmptyAndZeroLimitRequestsReturnNoFrames() {
        XCTAssertTrue(TVEpisodePreviewFrameSampler.sample([], limit: 4).isEmpty)
        XCTAssertTrue(TVEpisodePreviewFrameSampler.sample([frame(0)], limit: 0).isEmpty)
    }

    private func frame(_ index: Int) -> TrickplayPlaylist.Frame {
        TrickplayPlaylist.Frame(
            startTime: Double(index),
            imageURL: URL(string: "https://media.example/sheet.jpg")!,
            crop: .init(x: index * 160, y: 0, width: 160, height: 90),
            imageWidth: 16_000,
            imageHeight: 90
        )
    }
}
