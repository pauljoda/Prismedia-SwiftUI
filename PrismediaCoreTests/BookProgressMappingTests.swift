import XCTest

@testable import PrismediaCore

final class BookProgressMappingTests: XCTestCase {
    func testEPUBMappingsUseNormalizedCFIRangesAndListeningActivity() throws {
        let chapters = [
            epubChapter(number: 1, start: 0, end: 0.2, duration: 100),
            epubChapter(number: 2, start: 0.2, end: 0.6, duration: 200),
        ]
        let mappings = BookProgressMappingBuilder().build(
            bookID: bookID,
            chapters: chapters,
            readerMode: .paged,
            hasReadableRendition: true
        )

        XCTAssertEqual(mappings.map(\.startIndex), [0, 2_000])
        XCTAssertEqual(mappings.map(\.endIndex), [2_000, 6_000])
        XCTAssertEqual(mappings.map(\.total), [10_000, 10_000])
        XCTAssertTrue(mappings.allSatisfy { $0.unit == .cfi && $0.currentEntityID == bookID })

        let request = BookProgressMappingResolver().progressRequest(
            mapping: try XCTUnwrap(mappings.last),
            offsetSeconds: 50,
            durationSeconds: 200,
            activitySeconds: 17.5,
            completed: false
        )

        XCTAssertEqual(request.index, 3_000)
        XCTAssertEqual(request.activitySeconds, 17.5)
        XCTAssertEqual(request.activityKind, .listening)
    }

    func testImageChapterMapsWithinItsOwnPageRange() throws {
        let chapterID = UUID(uuidString: "00000000-0000-0000-0000-000000000088")!
        let track = musicTrack(number: 1, duration: 100)
        let chapter = BookChapterMapping(
            id: "chapter-1",
            title: "Chapter 1",
            order: 0,
            depth: 0,
            readTarget: .entityChapter(id: chapterID),
            readPageCount: 20,
            audioTrack: track,
            isCurrentReading: false,
            isCurrentAudio: false
        )
        let mapping = try XCTUnwrap(
            BookProgressMappingBuilder().build(
                bookID: bookID,
                chapters: [chapter],
                readerMode: .webtoon,
                hasReadableRendition: true
            ).first
        )

        XCTAssertEqual(mapping.currentEntityID, chapterID)
        XCTAssertEqual(mapping.unit, .page)
        XCTAssertEqual(mapping.startIndex, 0)
        XCTAssertEqual(mapping.endIndex, 19)
        XCTAssertEqual(mapping.total, 20)

        let request = BookProgressMappingResolver().progressRequest(
            mapping: mapping,
            offsetSeconds: 50,
            durationSeconds: 100,
            activitySeconds: nil,
            completed: false
        )
        XCTAssertEqual(request.index, 9)
    }

    func testAudioOnlyBookUsesCumulativeSecondsAcrossParts() {
        let chapters = [
            audioOnlyChapter(number: 1, duration: 100.2),
            audioOnlyChapter(number: 2, duration: 200.1),
        ]
        let mappings = BookProgressMappingBuilder().build(
            bookID: bookID,
            chapters: chapters,
            readerMode: nil,
            hasReadableRendition: false
        )

        XCTAssertEqual(mappings.map(\.unit), [.second, .second])
        XCTAssertEqual(mappings.map(\.startIndex), [0, 101])
        XCTAssertEqual(mappings.map(\.endIndex), [101, 302])
        XCTAssertEqual(mappings.map(\.total), [302, 302])
    }

    func testUnmatchedAudioPartIsNotGivenAReadableCursor() {
        let chapter = BookChapterMapping(
            id: "audio-only-part",
            title: "Unknown Part",
            order: 0,
            depth: 0,
            readTarget: nil,
            audioTrack: musicTrack(number: 1, duration: 100),
            isCurrentReading: false,
            isCurrentAudio: false
        )

        XCTAssertTrue(
            BookProgressMappingBuilder().build(
                bookID: bookID,
                chapters: [chapter],
                readerMode: .paged,
                hasReadableRendition: true
            ).isEmpty
        )
    }

    func testCanonicalCursorMapsBackToAudioWithFiveSecondRunway() throws {
        let track = musicTrack(number: 1, duration: 200)
        let mapping = BookProgressTrackMapping(
            trackID: track.id,
            currentEntityID: bookID,
            unit: .cfi,
            startIndex: 2_000,
            endIndex: 6_000,
            total: 10_000,
            mode: .paged
        )
        let progress = EntityProgressCapability(
            currentEntityID: bookID,
            unit: .cfi,
            index: 4_000,
            total: 10_000,
            mode: .paged,
            completedAt: nil,
            updatedAt: nil,
            workIndex: 4_000,
            workTotal: 10_000,
            location: "exact-readable-location"
        )

        let resume = try XCTUnwrap(
            BookProgressMappingResolver().audioResume(
                tracks: [track],
                mappings: [mapping],
                progress: progress
            )
        )

        XCTAssertEqual(resume.trackID, track.id)
        XCTAssertEqual(resume.trackOffsetSeconds, 95, accuracy: 0.001)
    }

    func testTrackMappingsRoundTripWithStableContractKeys() throws {
        let mapping = BookProgressTrackMapping(
            trackID: musicTrack(number: 1, duration: 100).id,
            currentEntityID: bookID,
            unit: .second,
            startIndex: 10,
            endIndex: 110,
            total: 300,
            mode: nil
        )

        let data = try JSONEncoder().encode(mapping)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["trackId"] as? String, mapping.trackID.uuidString)
        XCTAssertEqual(object["currentEntityId"] as? String, bookID.uuidString)
        XCTAssertEqual(object["unit"] as? String, "second")
        XCTAssertEqual(object["startIndex"] as? Int, 10)
        XCTAssertEqual(object["endIndex"] as? Int, 110)
        XCTAssertEqual(object["total"] as? Int, 300)
        XCTAssertEqual(try JSONDecoder().decode(BookProgressTrackMapping.self, from: data), mapping)
    }

    private let bookID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    private func epubChapter(
        number: Int,
        start: Double,
        end: Double,
        duration: Double
    ) -> BookChapterMapping {
        BookChapterMapping(
            id: "chapter-\(number)",
            title: "Chapter \(number)",
            order: number - 1,
            depth: 0,
            readTarget: .epub(location: "Text/chapter-\(number).xhtml"),
            readStartFraction: start,
            readEndFraction: end,
            audioTrack: musicTrack(number: number, duration: duration),
            isCurrentReading: false,
            isCurrentAudio: false
        )
    }

    private func audioOnlyChapter(number: Int, duration: Double) -> BookChapterMapping {
        BookChapterMapping(
            id: "part-\(number)",
            title: "Part \(number)",
            order: number - 1,
            depth: 0,
            readTarget: nil,
            audioTrack: musicTrack(number: number, duration: duration),
            isCurrentReading: false,
            isCurrentAudio: false
        )
    }

    private func musicTrack(number: Int, duration: Double) -> MusicTrack {
        MusicTrack(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", number))!,
            title: "Part \(number)",
            duration: duration,
            sortOrder: number - 1
        )
    }
}
