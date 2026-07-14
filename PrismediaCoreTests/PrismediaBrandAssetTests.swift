import CoreGraphics
import Foundation
import ImageIO
import XCTest

final class PrismediaBrandAssetTests: XCTestCase {
    func testColorAndNeutralPrismsShareCanvasAndVisibleGeometry() throws {
        let color = try image(named: "PrismediaPrismColor")
        let neutral = try image(named: "PrismediaPrismNeutral")

        XCTAssertEqual(color.width, neutral.width)
        XCTAssertEqual(color.height, neutral.height)
        XCTAssertEqual(try visibleBounds(of: color), try visibleBounds(of: neutral))
    }

    private func image(named name: String) throws -> CGImage {
        let url =
            repositoryRoot
            .appending(path: "PrismediaShared/Resources/Brand.xcassets")
            .appending(path: "\(name).imageset")
            .appending(path: "\(name).png")
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
        return try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
    }

    private func visibleBounds(of image: CGImage) throws -> CGRect {
        let bytesPerPixel = 4
        let bytesPerRow = image.width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: image.height * bytesPerRow)
        let context = try XCTUnwrap(
            CGContext(
                data: &pixels,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

        var minimumX = image.width
        var minimumY = image.height
        var maximumX = -1
        var maximumY = -1

        for y in 0..<image.height {
            for x in 0..<image.width where pixels[(y * bytesPerRow) + (x * bytesPerPixel) + 3] > 0 {
                minimumX = min(minimumX, x)
                minimumY = min(minimumY, y)
                maximumX = max(maximumX, x)
                maximumY = max(maximumY, y)
            }
        }

        XCTAssertGreaterThanOrEqual(maximumX, minimumX)
        XCTAssertGreaterThanOrEqual(maximumY, minimumY)
        return CGRect(
            x: minimumX,
            y: minimumY,
            width: maximumX - minimumX + 1,
            height: maximumY - minimumY + 1
        )
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
