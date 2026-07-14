import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
import XCTest

@testable import PrismediaCore

final class EntityMediaFeedPreparationServiceTests: XCTestCase {
    func testTechnicalDimensionsPrepareStableRatioWithoutLoadingSourceBytes() async throws {
        let item = makeItem(id: 1)
        let detail = try makeDetail(
            item: item,
            technicalWidth: 1_080,
            technicalHeight: 1_620
        )
        let loader = EntityMediaFeedPreparationLoaderSpy(details: [item.id: detail])
        let contentLoader = EntityMediaContentLoader(
            detailLoader: loader,
            sourceLoader: loader,
            retainedItems: [item]
        )

        let prepared = await EntityMediaFeedPreparationService().prepare(
            [item],
            contentLoader: contentLoader
        )

        XCTAssertEqual(prepared.map(\.id), [item.id])
        XCTAssertEqual(prepared.first?.aspectRatio ?? 0, 2.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(prepared.first?.projection?.mediaKind, .stillImage)
        let sourceRequestIDs = await loader.requestedSourceIDs()
        XCTAssertTrue(sourceRequestIDs.isEmpty)
    }

    func testMissingTechnicalDimensionsPrepareIntrinsicSourceRatioBeforePublishing() async throws {
        let item = makeItem(id: 2)
        let detail = try makeDetail(item: item, technicalWidth: nil, technicalHeight: nil)
        let source = try makePNGData(width: 3, height: 5)
        let loader = EntityMediaFeedPreparationLoaderSpy(
            details: [item.id: detail],
            sources: [item.id: source]
        )
        let contentLoader = EntityMediaContentLoader(
            detailLoader: loader,
            sourceLoader: loader,
            retainedItems: [item]
        )

        let prepared = await EntityMediaFeedPreparationService().prepare(
            [item],
            contentLoader: contentLoader
        )

        XCTAssertEqual(prepared.first?.aspectRatio ?? 0, 3.0 / 5.0, accuracy: 0.001)
        let sourceRequestIDs = await loader.requestedSourceIDs()
        XCTAssertEqual(sourceRequestIDs, [item.id])
    }

    func testVideoPreparationUsesPlayableAssetPresentationRatioBeforePublishing() async throws {
        let item = makeItem(id: 6)
        let playbackPath =
            "/api/entities/\(item.id.uuidString.lowercased())/files/source"
        let detail = try makeDetail(
            item: item,
            technicalWidth: 1_920,
            technicalHeight: 1_080,
            sourcePath: "/library/\(item.id.uuidString).mp4",
            mimeType: "video/mp4"
        )
        let loader = EntityMediaFeedPreparationLoaderSpy(details: [item.id: detail])
        let aspectRatioLoader = EntityImageVideoAspectRatioLoaderSpy(
            aspectRatiosByPath: [playbackPath: 9.0 / 16.0]
        )
        let contentLoader = EntityMediaContentLoader(
            detailLoader: loader,
            sourceLoader: loader,
            retainedItems: [item]
        )

        let prepared = await EntityMediaFeedPreparationService().prepare(
            [item],
            contentLoader: contentLoader,
            videoAspectRatioLoader: aspectRatioLoader
        )

        XCTAssertEqual(prepared.first?.aspectRatio ?? 0, 9.0 / 16.0, accuracy: 0.001)
        XCTAssertEqual(prepared.first?.projection?.mediaKind, .video)
        let requestedPaths = await aspectRatioLoader.requests()
        XCTAssertEqual(requestedPaths, [playbackPath])
        let sourceRequestIDs = await loader.requestedSourceIDs()
        XCTAssertTrue(sourceRequestIDs.isEmpty)
    }

    func testSourceMetadataFailureKeepsPreparedProjectionWithFallbackRatio() async throws {
        let item = makeItem(id: 5)
        let detail = try makeDetail(item: item, technicalWidth: nil, technicalHeight: nil)
        let loader = EntityMediaFeedPreparationLoaderSpy(details: [item.id: detail])
        let contentLoader = EntityMediaContentLoader(
            detailLoader: loader,
            sourceLoader: loader,
            retainedItems: [item]
        )

        let prepared = await EntityMediaFeedPreparationService().prepare(
            [item],
            contentLoader: contentLoader
        )

        XCTAssertEqual(prepared.first?.aspectRatio, 1)
        XCTAssertEqual(prepared.first?.projection?.mediaKind, .stillImage)
        XCTAssertNotNil(prepared.first?.projection?.sourcePath)
    }

    private func makeItem(id: Int) -> EntityThumbnail {
        EntityThumbnail(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", id))!,
            kind: .image,
            title: "Image \(id)",
            hasSourceMedia: true
        )
    }

    private func makeDetail(
        item: EntityThumbnail,
        technicalWidth: Int?,
        technicalHeight: Int?,
        sourcePath: String? = nil,
        mimeType: String = "image/png"
    ) throws -> EntityDetail {
        var capabilities: [[String: Any]] = [
            [
                "kind": "files",
                "items": [
                    [
                        "role": "source",
                        "path": sourcePath ?? "/library/\(item.id.uuidString).png",
                        "mimeType": mimeType,
                    ]
                ],
            ]
        ]
        if let technicalWidth, let technicalHeight {
            capabilities.append(
                [
                    "kind": "technical",
                    "width": technicalWidth,
                    "height": technicalHeight,
                ]
            )
        }
        let object: [String: Any] = [
            "id": item.id.uuidString,
            "kind": "image",
            "title": item.title,
            "hasSourceMedia": true,
            "capabilities": capabilities,
            "childrenByKind": [],
            "relationships": [],
        ]
        let data = try JSONSerialization.data(withJSONObject: object)
        return try PrismediaJSON.decoder().decode(EntityDetail.self, from: data)
    }

    private func makePNGData(width: Int, height: Int) throws -> Data {
        guard
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ),
            let image = context.makeImage()
        else { throw URLError(.cannotDecodeRawData) }

        let data = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                data,
                UTType.png.identifier as CFString,
                1,
                nil
            )
        else { throw URLError(.cannotCreateFile) }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw URLError(.cannotCreateFile) }
        return data as Data
    }
}
