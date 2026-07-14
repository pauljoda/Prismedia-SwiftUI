import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
import XCTest

@testable import PrismediaCore

final class ArtworkPalettePipelineTests: XCTestCase {
    func testConcurrentRequestsShareExtractionAndCacheThePalette() async throws {
        let loader = PaletteArtworkLoader(data: try samplePNGData())
        let pipeline = ArtworkPalettePipeline(artworkLoader: loader)
        let url = try XCTUnwrap(URL(string: "https://example.com/artwork.png"))

        async let first = pipeline.palette(for: url)
        async let second = pipeline.palette(for: url)
        async let third = pipeline.palette(for: url)
        let palettes = await [first, second, third]

        XCTAssertTrue(palettes.allSatisfy { $0 != nil })
        XCTAssertEqual(loader.requestCount, 1)

        let cached = await pipeline.palette(for: url)

        XCTAssertNotNil(cached)
        XCTAssertEqual(loader.requestCount, 1)
    }

    func testInvalidArtworkDoesNotCreateAPalette() async throws {
        let loader = PaletteArtworkLoader(data: Data("not an image".utf8))
        let pipeline = ArtworkPalettePipeline(artworkLoader: loader)
        let url = try XCTUnwrap(URL(string: "https://example.com/invalid.bin"))

        let palette = await pipeline.palette(for: url)

        XCTAssertNil(palette)
    }

    private func samplePNGData() throws -> Data {
        let width = 8
        let height = 8
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        for index in 0..<(width * height) {
            let offset = index * 4
            pixels[offset] = index.isMultiple(of: 2) ? 28 : 218
            pixels[offset + 1] = index.isMultiple(of: 2) ? 82 : 58
            pixels[offset + 2] = index.isMultiple(of: 2) ? 168 : 92
            pixels[offset + 3] = 255
        }
        let context = try XCTUnwrap(
            CGContext(
                data: &pixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        let image = try XCTUnwrap(context.makeImage())
        let data = NSMutableData()
        let destination = try XCTUnwrap(
            CGImageDestinationCreateWithData(
                data,
                UTType.png.identifier as CFString,
                1,
                nil
            )
        )
        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return data as Data
    }
}

private final class PaletteArtworkLoader: RemoteArtworkLoading, @unchecked Sendable {
    private let data: Data
    private let lock = NSLock()
    private var requests = 0

    init(data: Data) {
        self.data = data
    }

    var requestCount: Int {
        lock.withLock { requests }
    }

    func data(for url: URL) async throws -> Data {
        lock.withLock { requests += 1 }
        try await Task.sleep(for: .milliseconds(20))
        return data
    }

    func cachedData(for url: URL) -> Data? {
        nil
    }

    func prewarm(_ urls: [URL]) async {}
}
