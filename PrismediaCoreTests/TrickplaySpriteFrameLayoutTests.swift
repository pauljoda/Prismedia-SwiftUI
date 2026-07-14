import CoreGraphics
import Foundation
import XCTest

@testable import PrismediaCore

final class TrickplaySpriteFrameLayoutTests: XCTestCase {
    func testWideContainerFillsFromOneFourByThreeTile() {
        let frame = makeFrame(
            crop: .init(x: 640, y: 0, width: 640, height: 480),
            imageWidth: 1_280,
            imageHeight: 480
        )

        let layout = TrickplaySpriteFrameLayout(
            containerSize: CGSize(width: 960, height: 540),
            frame: frame
        )

        XCTAssertEqual(layout.scale, 1.5, accuracy: 0.001)
        XCTAssertEqual(layout.spriteSize.width, 1_920, accuracy: 0.001)
        XCTAssertEqual(layout.offset.width, -960, accuracy: 0.001)
        XCTAssertEqual(layout.offset.height, -90, accuracy: 0.001)
        assertSelectedTileCoversContainer(
            layout,
            frame: frame,
            container: .init(width: 960, height: 540)
        )
    }

    func testMatchingAspectRatioPreservesExactTileBounds() {
        let frame = makeFrame(
            crop: .init(x: 320, y: 180, width: 320, height: 180),
            imageWidth: 960,
            imageHeight: 360
        )

        let layout = TrickplaySpriteFrameLayout(
            containerSize: CGSize(width: 640, height: 360),
            frame: frame
        )

        XCTAssertEqual(layout.scale, 2, accuracy: 0.001)
        XCTAssertEqual(layout.offset.width, -640, accuracy: 0.001)
        XCTAssertEqual(layout.offset.height, -360, accuracy: 0.001)
        assertSelectedTileCoversContainer(
            layout,
            frame: frame,
            container: .init(width: 640, height: 360)
        )
    }

    private func assertSelectedTileCoversContainer(
        _ layout: TrickplaySpriteFrameLayout,
        frame: TrickplayPlaylist.Frame,
        container: CGSize
    ) {
        let selectedMinimumX = CGFloat(frame.crop.x) * layout.scale + layout.offset.width
        let selectedMaximumX = selectedMinimumX + CGFloat(frame.crop.width) * layout.scale
        let selectedMinimumY = CGFloat(frame.crop.y) * layout.scale + layout.offset.height
        let selectedMaximumY = selectedMinimumY + CGFloat(frame.crop.height) * layout.scale

        XCTAssertLessThanOrEqual(selectedMinimumX, 0.001)
        XCTAssertGreaterThanOrEqual(selectedMaximumX, container.width - 0.001)
        XCTAssertLessThanOrEqual(selectedMinimumY, 0.001)
        XCTAssertGreaterThanOrEqual(selectedMaximumY, container.height - 0.001)
    }

    private func makeFrame(
        crop: TrickplayPlaylist.Crop,
        imageWidth: Int,
        imageHeight: Int
    ) -> TrickplayPlaylist.Frame {
        TrickplayPlaylist.Frame(
            startTime: 0,
            imageURL: URL(string: "https://media.example/trickplay/sprite.jpg")!,
            crop: crop,
            imageWidth: imageWidth,
            imageHeight: imageHeight
        )
    }
}
