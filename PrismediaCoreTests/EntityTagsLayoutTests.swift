import SwiftUI
import XCTest

@testable import PrismediaCore

final class EntityTagsLayoutTests: XCTestCase {
    func testDenseTagMetricsStaySmallerThanStandardControls() {
        let metrics = EntityTagsMetrics.dense

        XCTAssertEqual(metrics.horizontalSpacing, PrismediaSpacing.small)
        XCTAssertEqual(metrics.verticalSpacing, PrismediaSpacing.small)
        XCTAssertEqual(metrics.horizontalPadding, PrismediaSpacing.medium)
        XCTAssertEqual(metrics.verticalPadding, PrismediaSpacing.extraSmall)
    }

    func testPackingWrapsTagsAndKeepsEveryRow() {
        let rows = EntityTagsPacking.rows(
            for: [64, 72, 52, 88],
            availableWidth: 150,
            spacing: 6
        )

        XCTAssertEqual(rows, [[0, 1], [2, 3]])
    }

    func testPackingPlacesAnOversizedTagOnItsOwnRow() {
        let rows = EntityTagsPacking.rows(
            for: [54, 180, 54],
            availableWidth: 140,
            spacing: 6
        )

        XCTAssertEqual(rows, [[0], [1], [2]])
    }

    @MainActor
    func testFlowLayoutGrowsToShowEveryWrappedRow() throws {
        let tags = EntityTagsFlowLayout(horizontalSpacing: 6, verticalSpacing: 6) {
            Color.red.frame(width: 64, height: 20)
            Color.green.frame(width: 72, height: 20)
            Color.blue.frame(width: 52, height: 20)
            Color.yellow.frame(width: 88, height: 20)
        }
        .frame(width: 150)

        let renderer = ImageRenderer(content: tags)
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.nsImage)

        XCTAssertEqual(image.size.width, 150, accuracy: 0.5)
        XCTAssertEqual(image.size.height, 46, accuracy: 0.5)
    }
}
