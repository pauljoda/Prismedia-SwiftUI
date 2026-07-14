import XCTest

@testable import PrismediaCore

final class DashboardTrickplayFrameSamplerTests: XCTestCase {
    func testTenFramesAreSampledEvenlyIntoFourHeroScenes() {
        let frames = (0..<10).map(frame)

        let sampled = DashboardTrickplayFrameSampler.sample(frames, limit: 4)

        XCTAssertEqual(sampled.map(\.startTime), [0, 3, 6, 9])
    }

    func testSamplingNeverExceedsTheRequestedSceneLimit() {
        let frames = (0..<40).map(frame)

        let sampled = DashboardTrickplayFrameSampler.sample(frames, limit: 6)

        XCTAssertEqual(sampled.count, 6)
        XCTAssertEqual(sampled.first?.startTime, 0)
        XCTAssertEqual(sampled.last?.startTime, 39)
    }

    private func frame(_ index: Int) -> TrickplayPlaylist.Frame {
        TrickplayPlaylist.Frame(
            startTime: Double(index),
            imageURL: URL(string: "https://media.example/sheet.jpg")!,
            crop: .init(x: index * 160, y: 0, width: 160, height: 90),
            imageWidth: 6_400,
            imageHeight: 90
        )
    }
}
