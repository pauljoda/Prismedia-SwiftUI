import Foundation
import XCTest

@testable import PrismediaCore

final class EntityImageMediaProjectionTests: XCTestCase {
    func testSourceFileUsesAuthenticatedEntityFileEndpointInsteadOfStoragePath() throws {
        let detail = try makeDetail(
            files: [
                ["role": "source", "path": "/library/private/photo.heic", "mimeType": "image/heic"]
            ]
        )

        let projection = EntityImageMediaProjection(detail: detail)

        XCTAssertEqual(
            projection.sourcePath,
            "/api/entities/11111111-1111-1111-1111-111111111111/files/source"
        )
        XCTAssertEqual(projection.mimeType, "image/heic")
        XCTAssertEqual(projection.mediaKind, .stillImage)
    }

    func testSourceRoleStillUsesAuthenticatedEndpointWhenItsPathLooksPublic() throws {
        let detail = try makeDetail(
            files: [
                [
                    "role": "source",
                    "path": "/assets/images/photo/source.png",
                    "mimeType": "image/png",
                ]
            ]
        )

        let projection = EntityImageMediaProjection(detail: detail)

        XCTAssertEqual(
            projection.sourcePath,
            "/api/entities/11111111-1111-1111-1111-111111111111/files/source"
        )
    }

    func testAnimatedStillRemainsAnImageInsteadOfBeingClassifiedAsVideo() throws {
        let detail = try makeDetail(
            files: [
                ["role": "source", "path": "/library/loop.gif", "mimeType": "image/gif"],
                ["role": "preview", "path": "/assets/loop.mp4", "mimeType": "video/mp4"],
            ]
        )

        let projection = EntityImageMediaProjection(detail: detail)

        XCTAssertEqual(projection.mediaKind, .animatedImage)
        XCTAssertEqual(projection.sourceRole, "source")
        XCTAssertNil(projection.playbackPath)
    }

    func testWebMImageUsesPublicMP4PreviewDirectlyAndRetainsOriginalForSharing() throws {
        let detail = try makeDetail(
            files: [
                ["role": "source", "path": "/library/motion.webm", "mimeType": "video/webm"],
                ["role": "preview", "path": "/assets/motion.mp4", "mimeType": "video/mp4"],
            ]
        )

        let projection = EntityImageMediaProjection(detail: detail)

        XCTAssertEqual(projection.mediaKind, .video)
        XCTAssertEqual(projection.playbackPath, "/assets/motion.mp4")
        XCTAssertEqual(
            projection.sourcePath,
            "/api/entities/11111111-1111-1111-1111-111111111111/files/source"
        )
    }

    func testNativeMP4SourceRemainsPlaybackPathSoItsAudioCanBeUnmuted() throws {
        let detail = try makeDetail(
            files: [
                ["role": "source", "path": "/library/motion-with-audio.mp4", "mimeType": "video/mp4"],
                ["role": "preview", "path": "/assets/motion-muted-preview.mp4", "mimeType": "video/mp4"],
            ]
        )

        let projection = EntityImageMediaProjection(detail: detail)

        XCTAssertEqual(projection.mediaKind, .video)
        XCTAssertEqual(
            projection.playbackPath,
            "/api/entities/11111111-1111-1111-1111-111111111111/files/source"
        )
    }

    func testNonAssetPreviewUsesAuthenticatedEntityFileEndpoint() throws {
        let detail = try makeDetail(
            files: [
                ["role": "source", "path": "/library/motion.webm", "mimeType": "video/webm"],
                ["role": "preview", "path": "/generated/motion.mp4", "mimeType": "video/mp4"],
            ]
        )

        let projection = EntityImageMediaProjection(detail: detail)

        XCTAssertEqual(
            projection.playbackPath,
            "/api/entities/11111111-1111-1111-1111-111111111111/files/preview"
        )
    }

    func testVideoSourceWithoutPreviewUsesAuthenticatedSourceRoleForPlayback() throws {
        let detail = try makeDetail(
            files: [
                [
                    "role": "source",
                    "path": "/assets/images/motion/source.webm",
                    "mimeType": "video/webm",
                ]
            ]
        )

        let projection = EntityImageMediaProjection(detail: detail)

        XCTAssertEqual(projection.mediaKind, .video)
        XCTAssertEqual(
            projection.playbackPath,
            "/api/entities/11111111-1111-1111-1111-111111111111/files/source"
        )
    }

    func testCoverFallbackWorksWhenTheEntityHasNoSourceFile() throws {
        let detail = try makeDetail(files: [], coverURL: "/assets/images/photo-cover.jpg")

        let projection = EntityImageMediaProjection(detail: detail)

        XCTAssertNil(projection.sourcePath)
        XCTAssertEqual(projection.fallbackArtworkPath, "/assets/images/photo-cover.jpg")
        XCTAssertEqual(projection.mediaKind, .stillImage)
    }

    private func makeDetail(
        files: [[String: String]],
        coverURL: String? = nil
    ) throws -> EntityDetail {
        var capabilities: [[String: Any]] = [
            ["kind": "files", "items": files]
        ]
        if let coverURL {
            capabilities.append(
                [
                    "kind": "images",
                    "supportedKinds": ["cover"],
                    "items": [],
                    "coverUrl": coverURL,
                ]
            )
        }
        let object: [String: Any] = [
            "id": "11111111-1111-1111-1111-111111111111",
            "kind": "image",
            "title": "Photo",
            "hasSourceMedia": !files.isEmpty,
            "capabilities": capabilities,
            "childrenByKind": [],
            "relationships": [],
        ]
        let data = try JSONSerialization.data(withJSONObject: object)
        return try PrismediaJSON.decoder().decode(EntityDetail.self, from: data)
    }
}
