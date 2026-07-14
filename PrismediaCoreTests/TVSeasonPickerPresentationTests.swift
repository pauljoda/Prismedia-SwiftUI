import XCTest

@testable import PrismediaCore

final class TVSeasonPickerPresentationTests: XCTestCase {
    func testExactlyTheSelectedSeasonReceivesSelectedSemantics() {
        let seasonIDs = [UUID(), UUID(), UUID()]
        let selectedID = seasonIDs[1]

        let selected = seasonIDs.filter {
            TVSeasonPickerPresentation.isSelected(
                seasonID: $0,
                selectedSeasonID: selectedID
            )
        }

        XCTAssertEqual(selected, [selectedID])
    }

    func testNoSeasonIsSelectedWithoutASelection() {
        XCTAssertFalse(
            TVSeasonPickerPresentation.isSelected(
                seasonID: UUID(),
                selectedSeasonID: nil
            )
        )
    }
}
