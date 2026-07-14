import XCTest

@testable import PrismediaCore

final class DashboardShelfPresentationTests: XCTestCase {
    func testEveryCanonicalDashboardSectionHasItsOwnRainbowRole() {
        let roles = DashboardCatalog.sections.map(\.colorRole)

        XCTAssertEqual(Set(roles).count, roles.count)
    }
}
