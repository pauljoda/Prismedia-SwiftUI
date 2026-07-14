import XCTest

@testable import PrismediaCore

final class ArtworkColorExtractorTests: XCTestCase {
    func testEdgeWeightedDominantColorBecomesTheBackground() throws {
        let pixels = borderedPixels(
            width: 12,
            height: 12,
            border: (18, 72, 132, 255),
            center: (224, 64, 48, 255)
        )

        let palette = try XCTUnwrap(
            ArtworkColorExtractor().palette(
                rgbaPixels: pixels,
                width: 12,
                height: 12
            )
        )

        XCTAssertGreaterThan(palette.background.blue, palette.background.red)
        XCTAssertGreaterThan(palette.background.blue, palette.background.green)
    }

    func testPaletteProducesDistinctReadablePrimaryAndSecondaryColors() throws {
        let pixels = stripedPixels(
            width: 18,
            height: 12,
            colors: [
                (12, 38, 72, 255),
                (225, 52, 96, 255),
                (44, 206, 164, 255),
            ]
        )

        let palette = try XCTUnwrap(
            ArtworkColorExtractor().palette(
                rgbaPixels: pixels,
                width: 18,
                height: 12
            )
        )

        XCTAssertGreaterThan(palette.primary.perceptualDistance(to: palette.secondary), 0.08)
        XCTAssertGreaterThanOrEqual(palette.primary.contrastRatio(with: palette.background), 4.5)
        XCTAssertGreaterThanOrEqual(palette.secondary.contrastRatio(with: palette.background), 4.5)
    }

    func testTransparentPixelsDoNotInfluenceThePalette() throws {
        var pixels = [UInt8](repeating: 0, count: 10 * 10 * 4)
        for index in 0..<(10 * 10) {
            let offset = index * 4
            pixels[offset] = 255
            pixels[offset + 2] = 255
            pixels[offset + 3] = 0
        }
        for y in 3..<7 {
            for x in 3..<7 {
                let offset = ((y * 10) + x) * 4
                pixels[offset] = 240
                pixels[offset + 1] = 128
                pixels[offset + 2] = 24
                pixels[offset + 3] = 255
            }
        }

        let palette = try XCTUnwrap(
            ArtworkColorExtractor().palette(
                rgbaPixels: pixels,
                width: 10,
                height: 10
            )
        )

        XCTAssertGreaterThan(palette.primary.red, palette.primary.blue)
        XCTAssertGreaterThan(palette.primary.green, palette.primary.blue)
    }

    func testFullyTransparentImageHasNoPalette() {
        let pixels = [UInt8](repeating: 0, count: 8 * 8 * 4)

        XCTAssertNil(
            ArtworkColorExtractor().palette(
                rgbaPixels: pixels,
                width: 8,
                height: 8
            )
        )
    }

    private func borderedPixels(
        width: Int,
        height: Int,
        border: (UInt8, UInt8, UInt8, UInt8),
        center: (UInt8, UInt8, UInt8, UInt8)
    ) -> [UInt8] {
        var pixels: [UInt8] = []
        pixels.reserveCapacity(width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let isBorder = x < 2 || x >= width - 2 || y < 2 || y >= height - 2
                pixels += components(isBorder ? border : center)
            }
        }
        return pixels
    }

    private func stripedPixels(
        width: Int,
        height: Int,
        colors: [(UInt8, UInt8, UInt8, UInt8)]
    ) -> [UInt8] {
        var pixels: [UInt8] = []
        pixels.reserveCapacity(width * height * 4)
        for _ in 0..<height {
            for x in 0..<width {
                let colorIndex = min((x * colors.count) / width, colors.count - 1)
                pixels += components(colors[colorIndex])
            }
        }
        return pixels
    }

    private func components(
        _ color: (UInt8, UInt8, UInt8, UInt8)
    ) -> [UInt8] {
        [color.0, color.1, color.2, color.3]
    }
}
