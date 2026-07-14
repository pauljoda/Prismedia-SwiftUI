import SwiftUI
import XCTest

@testable import PrismediaCore

@MainActor
final class EntityThumbnailArtworkFrameTests: XCTestCase {
    func testWideArtworkCannotChangeAPosterFramesMeasuredSize() throws {
        let frame = EntityThumbnailArtworkFrame(aspectRatio: 2.0 / 3.0) {
            Color.red
                .aspectRatio(16.0 / 9.0, contentMode: .fill)
        }
        .frame(width: 150)

        let renderer = ImageRenderer(content: frame)
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.nsImage)

        XCTAssertEqual(image.size.width, 150, accuracy: 0.5)
        XCTAssertEqual(image.size.height, 225, accuracy: 0.5)
    }

    func testOversizedArtworkCannotPaintAcrossTheGridGutterOrNeighbor() throws {
        let gridRow = HStack(spacing: 10) {
            Color.green
                .frame(width: 150, height: 225)

            EntityThumbnailArtworkFrame(aspectRatio: 2.0 / 3.0) {
                Color.red
                    .frame(width: 600, height: 600)
            }
            .frame(width: 150)
        }
        .frame(width: 310, height: 225)
        .background(Color.blue)

        let renderer = ImageRenderer(content: gridRow)
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.cgImage)
        let pixels = try rgbaPixels(from: image)

        assertPixel(pixels, image: image, x: 75, hasDominantChannel: .green)
        assertPixel(pixels, image: image, x: 155, hasDominantChannel: .blue)
        assertPixel(pixels, image: image, x: 235, hasDominantChannel: .red)
    }

    func testBookArtworkUsesPosterGeometryAndCoversTheFrame() {
        let presentation = EntityThumbnailArtworkPresentation(kind: .book)

        XCTAssertEqual(presentation.aspectRatio, 2.0 / 3.0)
        XCTAssertEqual(presentation.contentMode, .fill)
        XCTAssertFalse(presentation.isWide)
    }

    func testStudioArtworkUsesWideGeometryAndPreservesTheWholeLogo() {
        let presentation = EntityThumbnailArtworkPresentation(kind: .studio)

        XCTAssertEqual(presentation.aspectRatio, 21.0 / 9.0)
        XCTAssertEqual(presentation.contentMode, .fit)
        XCTAssertTrue(presentation.isWide)
    }

    func testGridUsesPosterFrameForSeriesAndWideFrameForVideos() {
        XCTAssertEqual(
            EntityThumbnailLayout.grid.artworkAspectRatio(
                for: EntityThumbnailArtworkPresentation(kind: .videoSeries)
            ),
            2.0 / 3.0
        )
        XCTAssertEqual(
            EntityThumbnailLayout.grid.artworkAspectRatio(
                for: EntityThumbnailArtworkPresentation(kind: .video)
            ),
            16.0 / 9.0
        )
    }

    func testMovieOwnedVideoUsesMoviePresentationAcrossSharedCards() {
        let item = EntityThumbnail(
            id: UUID(),
            kind: .video,
            title: "Movie source",
            parentKind: .movie
        )

        XCTAssertEqual(item.thumbnailArtworkPresentation.aspectRatio, 2.0 / 3.0)
        XCTAssertEqual(item.thumbnailArtworkPresentation.contentMode, .fill)
        XCTAssertFalse(item.thumbnailArtworkPresentation.isWide)
    }

    func testLayoutDoesNotFlattenTheEntityArtworkPresentation() {
        let presentation = EntityThumbnailArtworkPresentation(kind: .studio)

        XCTAssertEqual(
            EntityThumbnailLayout.wall.artworkAspectRatio(for: presentation),
            21.0 / 9.0
        )
        XCTAssertEqual(
            EntityThumbnailLayout.grid.artworkAspectRatio(for: presentation),
            21.0 / 9.0
        )
    }

    func testDecorationUsesTheVisibleArtworkFrameForItsInset() throws {
        let frame = EntityThumbnailArtworkFrame(aspectRatio: 16.0 / 9.0) {
            Color.red
                .frame(width: 600, height: 600)
        } decoration: {
            Color.clear
                .overlay(alignment: .leading) {
                    Color.green
                        .frame(width: 20)
                        .padding(.leading, 8)
                }
        }
        .frame(width: 160)

        let renderer = ImageRenderer(content: frame)
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.cgImage)
        let pixels = try rgbaPixels(from: image)

        assertPixel(pixels, image: image, x: 4, hasDominantChannel: .red)
        assertPixel(pixels, image: image, x: 10, hasDominantChannel: .green)
    }

    private func rgbaPixels(from image: CGImage) throws -> [UInt8] {
        let bytesPerPixel = 4
        let bytesPerRow = image.width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: bytesPerRow * image.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        let context = try XCTUnwrap(
            CGContext(
                data: &pixels,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            )
        )

        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return pixels
    }

    private func assertPixel(
        _ pixels: [UInt8],
        image: CGImage,
        x: Int,
        hasDominantChannel expected: RGBChannel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let y = image.height / 2
        let index = ((y * image.width) + x) * 4
        let actual = (red: pixels[index], green: pixels[index + 1], blue: pixels[index + 2])
        let channels = [actual.red, actual.green, actual.blue]
        let dominantIndex = channels.firstIndex(of: channels.max() ?? 0)

        XCTAssertEqual(dominantIndex, expected.rawValue, file: file, line: line)
    }

    private enum RGBChannel: Int {
        case red = 0
        case green = 1
        case blue = 2
    }
}
