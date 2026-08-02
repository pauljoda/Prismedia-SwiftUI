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
            .explicitLocator(serverLocation)
        )
        XCTAssertEqual(
            source?.fallbackTarget,
            BookReaderLocationTarget(
                location: "Text/server-chapter.xhtml",
                progression: 0.82
            )
        )
    }

    func testFallbackProgressMarkerRemainsAChapterTarget() {
        let source = EPUBReaderResumeSourceResolver().resolve(
            explicitLocation: "Text/server-chapter.xhtml#prismedia-progress=0.82",
            explicitProgression: nil,
            deviceLocation: nil
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

    func testServerLocatorRemainsAuthoritativeWhenDeviceLocatorIsOnlyFarther() {
        let serverLocation = """
            {
              "href": "Text/catelyn.xhtml",
              "locations": { "progression": 0.25, "totalProgression": 0.72 }
            }
            """
        let deviceLocation = """
            {
              "href": "Text/catelyn.xhtml",
              "locations": { "progression": 0.31, "totalProgression": 0.73 }
            }
            """

        let source = EPUBReaderResumeSourceResolver().resolve(
            explicitLocation: serverLocation,
            explicitProgression: nil,
            deviceLocation: deviceLocation
        )

        XCTAssertEqual(source, .explicitLocator(serverLocation))
    }

    func testServerCurrentLocationWinsWithoutComparingFurthestProgress() {
        let serverLocation = """
            {
              "href": "Text/catelyn.xhtml",
              "locations": { "progression": 0.25, "totalProgression": 0.74 }
            }
            """
        let deviceLocation = """
            {
              "href": "Text/catelyn.xhtml",
              "locations": { "progression": 0.31, "totalProgression": 0.73 }
            }
            """

        let source = EPUBReaderResumeSourceResolver().resolve(
            explicitLocation: serverLocation,
            explicitProgression: nil,
            deviceLocation: deviceLocation
        )

        XCTAssertEqual(source, .explicitLocator(serverLocation))
    }

    func testNewerDeviceLocatorWinsEvenWhenTheUserMovedBackward() {
        let serverLocation = """
            {
              "href": "Text/catelyn.xhtml",
              "locations": { "progression": 0.80, "totalProgression": 0.80 }
            }
            """
        let deviceLocation = """
            {
              "href": "Text/catelyn.xhtml",
              "locations": { "progression": 0.30, "totalProgression": 0.30 }
            }
            """
        let serverDate = Date(timeIntervalSince1970: 100)
        let deviceDate = Date(timeIntervalSince1970: 200)

        let source = EPUBReaderResumeSourceResolver().resolve(
            explicitLocation: serverLocation,
            explicitProgression: nil,
            explicitUpdatedAt: serverDate,
            deviceLocation: deviceLocation,
            deviceUpdatedAt: deviceDate
        )

        XCTAssertEqual(source, .device(deviceLocation))
    }

    func testOpaqueServerCFIFallsBackToTheReadableDeviceLocator() {
        let deviceLocation = """
            {
              "href": "Text/catelyn.xhtml",
              "locations": { "progression": 0.25 }
            }
            """

        let source = EPUBReaderResumeSourceResolver().resolve(
            explicitLocation: "epubcfi(/6/144!/4/2/2:10)",
            explicitProgression: nil,
            deviceLocation: deviceLocation
        )

        XCTAssertEqual(source, .device(deviceLocation))
        XCTAssertEqual(
            source?.fallbackTarget,
            BookReaderLocationTarget(
                location: "Text/catelyn.xhtml",
                progression: 0.25
            )
        )
    }
}
