import CoreGraphics
import Foundation
import XCTest

@testable import PrismediaCore

final class EntityGridArtworkPrewarmingTests: XCTestCase {
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
