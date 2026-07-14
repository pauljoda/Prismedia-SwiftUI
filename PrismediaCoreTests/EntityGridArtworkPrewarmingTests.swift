import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
import XCTest

@testable import PrismediaCore

final class EntityGridArtworkPrewarmingTests: XCTestCase {
    func testWindowSelectsOnlyTheNextUniqueArtworkPaths() {
        let items = [
            thumbnail(1, path: "/covers/one.jpg"),
            thumbnail(2, path: nil),
            thumbnail(3, path: "/covers/three.jpg"),
            thumbnail(4, path: "/covers/three.jpg"),
            thumbnail(5, path: "/covers/five.jpg"),
            thumbnail(6, path: "/covers/six.jpg"),
        ]

        let paths = EntityGridArtworkPrewarming.paths(
            after: items[0].id,
            in: items,
            limit: 2
        )

        XCTAssertEqual(paths, ["/covers/three.jpg", "/covers/five.jpg"])
    }

    func testWindowIsEmptyForTheLastOrUnknownItem() {
        let items = [thumbnail(1, path: "/covers/one.jpg")]

        XCTAssertTrue(EntityGridArtworkPrewarming.paths(after: items[0].id, in: items).isEmpty)
        XCTAssertTrue(EntityGridArtworkPrewarming.paths(after: UUID(), in: items).isEmpty)
    }

    func testPipelineCoalescesPrewarmAndVisibleLoadThenCachesTheResult() async throws {
        let url = URL(string: "https://media.example.test/assets/cover.jpg")!
        let loader = ArtworkLoaderSpy(data: Data([1, 2, 3]))
        let pipeline = RemoteArtworkPipeline(loader: loader, cacheLimit: 4)

        async let prewarm: Void = pipeline.prewarm([url])
        async let visible = pipeline.data(for: url)
        _ = await prewarm
        let visibleData = try await visible
        let cachedData = try await pipeline.data(for: url)

        XCTAssertEqual(visibleData, Data([1, 2, 3]))
        XCTAssertEqual(cachedData, visibleData)
        XCTAssertEqual(pipeline.cachedData(for: url), visibleData)
        let requestCount = await loader.requestCount()
        XCTAssertEqual(requestCount, 1)
    }

    func testConcurrentDecodedRequestsShareTransportAndDecodeThenReuseTheDecodedCache()
        async throws
    {
        let url = URL(string: "https://media.example.test/assets/cover.jpg")!
        let loader = ArtworkLoaderSpy(data: Data([1, 2, 3]))
        let pipeline = RemoteArtworkPipeline(
            loader: loader,
            cacheLimit: 4,
            decodedByteCostLimit: 1_024,
            imageDecoder: { data, maxPixelSize in
                try await loader.decode(data, maxPixelSize: maxPixelSize)
            }
        )

        async let first = pipeline.image(for: url, maxPixelSize: 512)
        async let second = pipeline.image(for: url, maxPixelSize: 512)
        async let third = pipeline.image(for: url, maxPixelSize: 512)
        _ = try await [first, second, third]
        _ = try await pipeline.image(for: url, maxPixelSize: 512)

        let requestCount = await loader.requestCount()
        let decodeCount = await loader.decodeCount(maxPixelSize: 512)
        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(decodeCount, 1)
        XCTAssertNotNil(pipeline.cachedImage(for: url, maxPixelSize: 512))
    }

    func testDecodedCacheEvictsLeastRecentlyUsedImagesToStayWithinItsByteBudget()
        async throws
    {
        let url = URL(string: "https://media.example.test/assets/cover.jpg")!
        let loader = ArtworkLoaderSpy(data: Data([1, 2, 3]))
        let pipeline = RemoteArtworkPipeline(
            loader: loader,
            cacheLimit: 4,
            decodedByteCostLimit: 7,
            imageDecoder: { data, maxPixelSize in
                try await loader.decode(data, maxPixelSize: maxPixelSize)
            }
        )

        _ = try await pipeline.image(for: url, maxPixelSize: 512)
        _ = try await pipeline.image(for: url, maxPixelSize: 1_024)
        _ = try await pipeline.image(for: url, maxPixelSize: 512)

        let requestCount = await loader.requestCount()
        let smallDecodeCount = await loader.decodeCount(maxPixelSize: 512)
        let largeDecodeCount = await loader.decodeCount(maxPixelSize: 1_024)
        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(smallDecodeCount, 2)
        XCTAssertEqual(largeDecodeCount, 1)
    }

    func testMicrobenchmark4096PixelFixtureDownsamplesThumbnailMemoryAndReusesDecodedCache()
        async throws
    {
        let fixture = try makeJPEGData(pixelSize: 4_096)
        let loader = ArtworkLoaderSpy(data: fixture)
        let pipeline = RemoteArtworkPipeline(loader: loader)
        let url = URL(string: "https://media.example.test/assets/4096-fixture.jpg")!
        let clock = ContinuousClock()

        let largeStart = clock.now
        let largeImage = try await pipeline.image(for: url, maxPixelSize: 2_048)
        let largeDuration = largeStart.duration(to: clock.now)
        let thumbnailStart = clock.now
        let thumbnailImage = try await pipeline.image(for: url, maxPixelSize: 512)
        let thumbnailDuration = thumbnailStart.duration(to: clock.now)
        let cacheStart = clock.now
        let cachedThumbnail = try await pipeline.image(for: url, maxPixelSize: 512)
        let cacheDuration = cacheStart.duration(to: clock.now)

        let largeBytes = largeImage.bytesPerRow * largeImage.height
        let thumbnailBytes = thumbnailImage.bytesPerRow * thumbnailImage.height
        print(
            "PERF_MICROBENCH remote-artwork fixture=4096 "
                + "decoded_2048_bytes=\(largeBytes) decoded_512_bytes=\(thumbnailBytes) "
                + "decode_2048=\(largeDuration) decode_512=\(thumbnailDuration) "
                + "cached_512=\(cacheDuration)"
        )
        XCTAssertEqual(largeImage.width, 2_048)
        XCTAssertEqual(thumbnailImage.width, 512)
        XCTAssertEqual(largeBytes, thumbnailBytes * 16)
        XCTAssertTrue(thumbnailImage === cachedThumbnail)
        let requestCount = await loader.requestCount()
        XCTAssertEqual(requestCount, 1)
    }

    private func thumbnail(_ id: Int, path: String?) -> EntityThumbnail {
        EntityThumbnail(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", id))!,
            kind: .video,
            title: "Item \(id)",
            coverThumb2xURL: path
        )
    }

    private func makeJPEGData(pixelSize: Int) throws -> Data {
        guard
            let context = CGContext(
                data: nil,
                width: pixelSize,
                height: pixelSize,
                bitsPerComponent: 8,
                bytesPerRow: pixelSize * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            throw URLError(.cannotCreateFile)
        }
        context.setFillColor(red: 0.08, green: 0.22, blue: 0.48, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize))
        guard let image = context.makeImage() else {
            throw URLError(.cannotCreateFile)
        }

        let data = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                data,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            )
        else {
            throw URLError(.cannotCreateFile)
        }
        CGImageDestinationAddImage(
            destination,
            image,
            [kCGImageDestinationLossyCompressionQuality: 0.82] as CFDictionary
        )
        guard CGImageDestinationFinalize(destination) else {
            throw URLError(.cannotCreateFile)
        }
        return data as Data
    }
}

private actor ArtworkLoaderSpy: HTTPDataLoading {
    private let responseData: Data
    private var count = 0
    private var decodeCounts: [Int: Int] = [:]

    init(data: Data) {
        responseData = data
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        count += 1
        try await Task.sleep(for: .milliseconds(20))
        let response = URLResponse(
            url: request.url!,
            mimeType: "image/jpeg",
            expectedContentLength: responseData.count,
            textEncodingName: nil
        )
        return (responseData, response)
    }

    func requestCount() -> Int {
        count
    }

    func decode(_ data: Data, maxPixelSize: Int) throws -> CGImage {
        decodeCounts[maxPixelSize, default: 0] += 1
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard
            let context = CGContext(
                data: nil,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ),
            let image = context.makeImage()
        else {
            throw URLError(.cannotDecodeRawData)
        }
        return image
    }

    func decodeCount(maxPixelSize: Int) -> Int {
        decodeCounts[maxPixelSize, default: 0]
    }
}
