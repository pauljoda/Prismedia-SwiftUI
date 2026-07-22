import Foundation
import XCTest

@testable import PrismediaCore

final class RequestActivityFilesTests: XCTestCase {
    func testLegacyResponseDecodesWithoutLedgerMetadata() throws {
        let files = try JSONDecoder().decode(RequestActivityFiles.self, from: Data(#"""
        {"imported":true,"files":[{"name":"Book.epub","sizeBytes":2048,"progress":1}]}
        """#.utf8))

        XCTAssertTrue(files.imported)
        XCTAssertNil(files.phase)
        XCTAssertEqual(files.files.first?.name, "Book.epub")
        XCTAssertNil(files.files.first?.status?.value)
        XCTAssertNil(files.files.first?.sourceRelativePath)
    }

    func testEnrichedResponseDecodesClosedSetValuesAndMappings() throws {
        let files = try JSONDecoder().decode(RequestActivityFiles.self, from: Data(#"""
        {
          "imported": true,
          "phase": "imported",
          "files": [{
            "id": "file-1",
            "name": "Movie.mkv",
            "sizeBytes": 4096,
            "progress": 1,
            "sourceRelativePath": "payload/Movie.mkv",
            "destinationRelativePath": "Movies/Movie/Movie.mkv",
            "role": "media",
            "contentKind": "video",
            "status": "imported",
            "decision": "place-new",
            "technicalError": null
          }]
        }
        """#.utf8))

        XCTAssertEqual(files.phase?.value, .imported)
        let file = try XCTUnwrap(files.files.first)
        XCTAssertEqual(file.id, "file-1")
        XCTAssertEqual(file.role?.value, .media)
        XCTAssertEqual(file.contentKind?.value, .video)
        XCTAssertEqual(file.status?.value, .imported)
        XCTAssertEqual(file.decision?.value, .placeNew)
        XCTAssertEqual(file.destinationRelativePath, "Movies/Movie/Movie.mkv")
    }

    func testPresentationPolicyUsesCountProgressAndExpandsPartialResults() {
        let complete = RequestActivityFiles.fixture(statuses: [.imported, .imported])
        let partial = RequestActivityFiles.fixture(statuses: [.imported, .skipped])

        XCTAssertEqual(RequestActivityFilesPresentationPolicy.progress(for: complete), .init(processed: 2, total: 2))
        XCTAssertFalse(RequestActivityFilesPresentationPolicy.isExpandedByDefault(complete))
        XCTAssertTrue(RequestActivityFilesPresentationPolicy.isExpandedByDefault(partial))
    }

    func testStaleWarningAppearsOnThirdConsecutiveFailureAndClearsOnSuccess() {
        var state = RequestActivityFilesLoadState.loaded(.fixture(statuses: [.imported]))

        state.recordRefreshFailure()
        state.recordRefreshFailure()
        XCTAssertFalse(state.showsStaleWarning)
        state.recordRefreshFailure()
        XCTAssertTrue(state.showsStaleWarning)
        XCTAssertNotNil(state.files)

        state.recordSuccess(.fixture(statuses: [.imported]))
        XCTAssertFalse(state.showsStaleWarning)
    }
}

private extension RequestActivityFiles {
    static func fixture(statuses: [RequestActivityFileStatus.Value]) -> RequestActivityFiles {
        RequestActivityFiles(
            imported: true,
            phase: .init(value: .imported),
            files: statuses.enumerated().map { index, status in
                RequestActivityFile(
                    id: "file-\(index)",
                    name: "File \(index)",
                    sizeBytes: 1,
                    progress: 1,
                    sourceRelativePath: nil,
                    destinationRelativePath: nil,
                    role: .init(value: .media),
                    contentKind: .init(value: .video),
                    status: .init(value: status),
                    decision: .init(value: .placeNew),
                    technicalError: nil
                )
            }
        )
    }
}
