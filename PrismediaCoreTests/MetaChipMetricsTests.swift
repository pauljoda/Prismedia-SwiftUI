import XCTest

@testable import PrismediaCore

final class MetaChipMetricsTests: XCTestCase {
    func testCompactThumbnailMetadataDoesNotReadAsButtonSizedControls() {
        let metrics = MetaChipMetrics.compact

        XCTAssertEqual(metrics.rowSpacing, PrismediaSpacing.extraSmall)
        XCTAssertEqual(metrics.contentSpacing, PrismediaSpacing.extraExtraSmall)
        XCTAssertEqual(metrics.horizontalPadding, PrismediaSpacing.extraSmall)
        XCTAssertEqual(metrics.verticalPadding, PrismediaSpacing.extraExtraSmall)
    }
}
