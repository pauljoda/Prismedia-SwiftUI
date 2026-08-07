import XCTest

@testable import PrismediaCore

final class RemoteArtworkLoadingTests: XCTestCase {
    func testSVGArtworkUsesPlatformDecoderAtRequestedDisplayResolution() throws {
        let svg = Data(
            """
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 120">
              <rect width="300" height="120" fill="transparent"/>
              <rect x="30" y="35" width="240" height="50" rx="8" fill="black"/>
            </svg>
            """.utf8
        )

        let image = try downsampleRemoteArtworkImage(svg, maxPixelSize: 600)

        XCTAssertEqual(image.width, 600)
        XCTAssertEqual(image.height, 240)
    }
}
