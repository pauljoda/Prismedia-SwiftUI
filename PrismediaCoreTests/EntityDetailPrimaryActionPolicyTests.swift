import XCTest

@testable import PrismediaCore

final class EntityDetailPrimaryActionPolicyTests: XCTestCase {
    func testFirstAvailableActionReceivesTheSinglePaletteTint() {
        let actions = [
            EntityDetailAction(
                id: .resume,
                title: "Resume",
                systemImage: "play.fill",
                isSelected: false,
                isPrimary: true
            ),
            EntityDetailAction(
                id: .listen,
                title: "Listen",
                systemImage: "headphones",
                isSelected: false,
                isPrimary: true
            ),
        ]

        XCTAssertEqual(EntityDetailPrimaryActionPolicy.tintedActionID(in: actions), .resume)
    }

    func testNoActionProducesNoPaletteTintTarget() {
        XCTAssertNil(EntityDetailPrimaryActionPolicy.tintedActionID(in: []))
    }
}
