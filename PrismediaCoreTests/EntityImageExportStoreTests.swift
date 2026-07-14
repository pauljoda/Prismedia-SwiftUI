import Foundation
import XCTest

@testable import PrismediaCore

final class EntityImageExportStoreTests: XCTestCase {
    func testExportCreatesALocalSafeFilenameThatPreservesTheMediaType() async throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = EntityImageExportStore(rootDirectory: root)
        let payload = Data("original image".utf8)

        let artifact = try await store.createArtifact(
            data: payload,
            title: "../../Summer: Night?.jpeg",
            mimeType: "image/jpeg"
        )

        XCTAssertTrue(artifact.fileURL.isFileURL)
        XCTAssertTrue(artifact.fileURL.path.hasPrefix(root.path))
        XCTAssertEqual(artifact.fileURL.pathExtension, "jpg")
        XCTAssertFalse(artifact.fileURL.lastPathComponent.contains(".."))
        XCTAssertFalse(artifact.fileURL.lastPathComponent.contains("/"))
        XCTAssertFalse(artifact.fileURL.lastPathComponent.contains(":"))
        XCTAssertFalse(artifact.fileURL.lastPathComponent.contains("?"))
        XCTAssertFalse(artifact.fileURL.absoluteString.contains("api_key"))
        XCTAssertFalse(artifact.fileURL.absoluteString.contains("Authorization"))
        XCTAssertEqual(try Data(contentsOf: artifact.fileURL), payload)
    }

    func testRemovingArtifactsDeletesTheirFilesAndSessionDirectory() async throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = EntityImageExportStore(rootDirectory: root)
        let first = try await store.createArtifact(
            data: Data([1]),
            title: "Photo.png",
            mimeType: "image/png"
        )
        let second = try await store.createArtifact(
            data: Data([2]),
            title: "Photo.png",
            mimeType: "image/png"
        )

        XCTAssertNotEqual(first.fileURL, second.fileURL)
        await store.removeArtifact(first)
        XCTAssertFalse(FileManager.default.fileExists(atPath: first.fileURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: second.fileURL.path))

        await store.removeAll()
        XCTAssertFalse(FileManager.default.fileExists(atPath: second.fileURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.path))
    }

    private func temporaryRoot() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "prismedia-image-export-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
    }
}
