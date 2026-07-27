import CoreGraphics
import CoreImage
import Foundation
import XCTest

@testable import PrismediaCore

final class EntityGridArtworkPrewarmingTests: XCTestCase {
    func testOnlyOneItemPerBatchStartsPrewarming() {
        let items = (0..<17).map {
            EntityThumbnail(id: UUID(), kind: .movie, title: "Movie \($0)")
        }

        XCTAssertTrue(
            EntityGridArtworkPrewarming.shouldStartBatch(
                after: items[0].id,
                in: items
            )
        )
        XCTAssertFalse(
            EntityGridArtworkPrewarming.shouldStartBatch(
                after: items[1].id,
                in: items
            )
        )
        XCTAssertTrue(
            EntityGridArtworkPrewarming.shouldStartBatch(
                after: items[8].id,
                in: items
            )
        )
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

    func testCompressedCacheDoesNotRetainAnEntryLargerThanItsByteBudget() async throws {
        let url = URL(string: "https://media.example.test/assets/oversized-cover.jpg")!
        let loader = ArtworkLoaderSpy(data: Data([1, 2, 3]))
        let pipeline = RemoteArtworkPipeline(
            loader: loader,
            cacheLimit: 4,
            compressedByteCostLimit: 2
        )

        _ = try await pipeline.data(for: url)
        _ = try await pipeline.data(for: url)

        XCTAssertNil(pipeline.cachedData(for: url))
        let requestCount = await loader.requestCount()
        XCTAssertEqual(requestCount, 2)
    }

    func testArtworkExtensionPipelineRendersOnceThenReusesTheStaticComposition() async throws {
        let url = URL(string: "https://media.example.test/assets/wide-cover.jpg")!
        let loader = StaticArtworkLoader(image: try makeImage(width: 120, height: 68))
        let pipeline = ArtworkExtensionImagePipeline(
            context: CIContext(options: [.useSoftwareRenderer: true]),
            byteCostLimit: 1_000_000
        )

        let first = await pipeline.image(
            for: url,
            artworkLoader: loader,
            sourceAspectRatio: 16.0 / 9.0,
            outputAspectRatio: 6.0 / 5.0,
            maxPixelSize: 120
        )
        let second = await pipeline.image(
            for: url,
            artworkLoader: loader,
            sourceAspectRatio: 16.0 / 9.0,
            outputAspectRatio: 6.0 / 5.0,
            maxPixelSize: 120
        )

        XCTAssertEqual(first?.width, 120)
        XCTAssertEqual(first?.height, 100)
        XCTAssertEqual(second?.width, first?.width)
        XCTAssertEqual(second?.height, first?.height)
        XCTAssertEqual(loader.cachedImageRequestCount, 1)
    }

    private func makeImage(width: Int, height: Int) throws -> CGImage {
        let context = try XCTUnwrap(
            CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.setFillColor(CGColor(red: 0.12, green: 0.42, blue: 0.86, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return try XCTUnwrap(context.makeImage())
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

private final class StaticArtworkLoader: RemoteArtworkLoading, @unchecked Sendable {
    private let image: CGImage
    private let lock = NSLock()
    private var cachedRequests = 0

    init(image: CGImage) {
        self.image = image
    }

    var cachedImageRequestCount: Int {
        lock.withLock { cachedRequests }
    }

    func data(for url: URL) async throws -> Data {
        throw URLError(.resourceUnavailable)
    }

    func cachedData(for url: URL) -> Data? {
        nil
    }

    func cachedImage(for url: URL, maxPixelSize: Int) -> CGImage? {
        lock.withLock { cachedRequests += 1 }
        return image
    }

    func prewarm(_ urls: [URL]) async {}
}
