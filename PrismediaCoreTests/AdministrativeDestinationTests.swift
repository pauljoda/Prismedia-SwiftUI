import XCTest

@testable import PrismediaCore

final class AdministrativeDestinationTests: XCTestCase {
    func testManageAndOperateUseDistinctTypedDestinations() {
        XCTAssertEqual(
            ModeCatalog.manage.destinations.compactMap(\.manage),
            [.files, .identify, .request]
        )
        XCTAssertTrue(ModeCatalog.manage.destinations.allSatisfy { $0.administration == nil })
        XCTAssertEqual(
            ModeCatalog.operate.destinations.compactMap(\.administration),
            [.plugins, .jobs, .settings]
        )
        XCTAssertTrue(ModeCatalog.operate.destinations.allSatisfy { $0.manage == nil })
        XCTAssertTrue(ModeCatalog.manage.requiresAdmin)
        XCTAssertTrue(ModeCatalog.operate.requiresAdmin)
        XCTAssertTrue(
            (ModeCatalog.manage.destinations + ModeCatalog.operate.destinations).allSatisfy {
                $0.entityList == nil
            })
    }
}
