import XCTest

@testable import PrismediaCore

final class ArtworkColorTests: XCTestCase {
    func testForegroundChoosesDarkInkForPaleArtworkAndLightInkForDarkArtwork() {
        let pale = ArtworkColor(red: 0.96, green: 0.88, blue: 0.68)
        let dark = ArtworkColor(red: 0.08, green: 0.12, blue: 0.25)

        XCTAssertEqual(pale.contrastingForeground, ArtworkColor(red: 0, green: 0, blue: 0))
        XCTAssertEqual(dark.contrastingForeground, ArtworkColor(red: 1, green: 1, blue: 1))
    }

    func testForegroundMeetsNormalTextContrastAcrossTheColorSpace() {
        for red in stride(from: 0.0, through: 1.0, by: 0.1) {
            for green in stride(from: 0.0, through: 1.0, by: 0.1) {
                for blue in stride(from: 0.0, through: 1.0, by: 0.1) {
                    let background = ArtworkColor(red: red, green: green, blue: blue)
                    XCTAssertGreaterThanOrEqual(
                        background.contrastRatio(with: background.contrastingForeground), 4.5
                    )
                }
            }
        }
    }
}
