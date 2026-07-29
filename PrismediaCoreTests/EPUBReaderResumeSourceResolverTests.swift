import XCTest

@testable import PrismediaCore

final class EPUBReaderResumeSourceResolverTests: XCTestCase {
    func testServerLocationWinsOverADeviceLocator() {
        let serverLocation = """
            {
              "href": "Text/server-chapter.xhtml",
              "locations": { "progression": 0.82 }
            }
            """
        let deviceLocation = """
            {
              "href": "Text/device-chapter.xhtml",
              "locations": { "progression": 0.25 }
            }
            """

        let source = EPUBReaderResumeSourceResolver().resolve(
            explicitLocation: serverLocation,
            explicitProgression: nil,
            deviceLocation: deviceLocation
        )

        XCTAssertEqual(
            source,
            .explicit(
                BookReaderLocationTarget(
                    location: "Text/server-chapter.xhtml",
                    progression: 0.82
                )
            )
        )
    }

    func testMissingServerLocationFallsBackToTheDeviceLocator() {
        let deviceLocation = """
            {
              "href": "Text/device-chapter.xhtml",
              "locations": { "progression": 0.25 }
            }
            """

        let source = EPUBReaderResumeSourceResolver().resolve(
            explicitLocation: nil,
            explicitProgression: nil,
            deviceLocation: deviceLocation
        )

        XCTAssertEqual(source, .device(deviceLocation))
        XCTAssertEqual(
            source?.fallbackTarget,
            BookReaderLocationTarget(
                location: "Text/device-chapter.xhtml",
                progression: 0.25
            )
        )
    }
}
