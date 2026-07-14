import Foundation
import XCTest

final class AppConfigurationTests: XCTestCase {
    func testIPadSupportsEveryOrientationWithoutRequiringFullScreen() throws {
        let infoURL = repositoryRoot.appending(path: "PrismediaiOS/Info.plist")
        let data = try Data(contentsOf: infoURL)
        let propertyList = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, format: nil)
                as? [String: Any]
        )
        let orientations = try XCTUnwrap(
            propertyList["UISupportedInterfaceOrientations~ipad"] as? [String]
        )

        XCTAssertEqual(
            Set(orientations),
            [
                "UIInterfaceOrientationPortrait",
                "UIInterfaceOrientationPortraitUpsideDown",
                "UIInterfaceOrientationLandscapeLeft",
                "UIInterfaceOrientationLandscapeRight",
            ]
        )
        XCTAssertNil(propertyList["UIRequiresFullScreen"])
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
