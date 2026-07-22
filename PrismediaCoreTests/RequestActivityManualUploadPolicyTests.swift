import XCTest

@testable import PrismediaCore

final class RequestActivityManualUploadPolicyTests: XCTestCase {
    func testContentUploadAvailabilityMatchesCanonicalActiveAndReplacementGates() {
        XCTAssertTrue(available(kind: .book, owned: false, status: "awaiting-selection"))
        XCTAssertTrue(available(kind: .movie, owned: false, status: "failed"))
        XCTAssertTrue(available(kind: .videoSeason, owned: false, status: "cancelled"))
        XCTAssertFalse(available(kind: .book, owned: true, status: "downloading"))
        XCTAssertFalse(available(kind: .book, owned: false, status: "imported"))
        XCTAssertTrue(available(kind: .book, owned: true, status: "imported"))
        XCTAssertTrue(available(kind: .audioLibrary, owned: true, status: nil))
        XCTAssertFalse(available(kind: .videoSeason, owned: true, status: nil))
        XCTAssertFalse(available(kind: .gallery, owned: true, status: nil))
    }

    func testContentValidationAllowsCompanionsButRequiresKindCompatiblePrimary() throws {
        let files = [
            file("Dune.epub", size: 4_200_000),
            file("cover.jpg", size: 820_000),
        ]
        XCTAssertNoThrow(
            try RequestActivityManualUploadPolicy.validateContent(
                files,
                kind: .book,
                bookRendition: nil
            )
        )
        XCTAssertThrowsError(
            try RequestActivityManualUploadPolicy.validateContent(
                [file("notes.txt", size: 2_000)],
                kind: .book,
                bookRendition: nil
            )
        )
    }

    func testContentValidationRejectsEmptyDuplicateAndOversizedSelections() {
        XCTAssertThrowsError(
            try RequestActivityManualUploadPolicy.validateContent(
                [file("Dune.epub", size: 0)],
                kind: .book,
                bookRendition: nil
            )
        )
        XCTAssertThrowsError(
            try RequestActivityManualUploadPolicy.validateContent(
                [file("Dune.epub", size: 1), file("DUNE.EPUB", size: 1)],
                kind: .book,
                bookRendition: nil
            )
        )
        XCTAssertThrowsError(
            try RequestActivityManualUploadPolicy.validateContent(
                [file("Dune.epub", size: RequestActivityManualUploadPolicy.contentUploadLimitBytes + 1)],
                kind: .book,
                bookRendition: nil
            )
        )
    }

    func testTorrentValidationRequiresOneNonemptyTorrentFile() throws {
        XCTAssertNoThrow(
            try RequestActivityManualUploadPolicy.validateTorrent(file("release.torrent", size: 84_000))
        )
        XCTAssertThrowsError(
            try RequestActivityManualUploadPolicy.validateTorrent(file("release.txt", size: 84_000))
        )
        XCTAssertThrowsError(
            try RequestActivityManualUploadPolicy.validateTorrent(file("release.torrent", size: 0))
        )
    }

    private func available(
        kind: EntityKind,
        owned: Bool,
        status: String?
    ) -> Bool {
        RequestActivityManualUploadPolicy.canUploadContent(
            kind: kind,
            hasOwnedContent: owned,
            acquisitionStatus: status.map(AcquisitionStatus.init(rawValue:))
        )
    }

    private func file(_ name: String, size: Int64) -> RequestActivityManualUploadFile {
        RequestActivityManualUploadFile(
            url: URL(fileURLWithPath: "/preview/\(name)"),
            fileName: name,
            sizeBytes: size
        )
    }
}
