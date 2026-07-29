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
            audioTrack: track
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
            audioTrack: musicTrack(number: 1, duration: 100)
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

    func testSharedEPUBBoundaryBelongsToTheLaterChapter() throws {
        let chapters = [
            epubChapter(number: 1, start: 0, end: 0.5, duration: 100),
            epubChapter(number: 2, start: 0.5, end: 1, duration: 100),
        ]
        let mappings = BookProgressMappingBuilder().build(
            bookID: bookID,
            chapters: chapters,
            readerMode: .paged,
            hasReadableRendition: true
        )
        let progress = canonicalProgress(index: 5_000, location: nil)

        let mapping = try XCTUnwrap(
            BookProgressMappingResolver().mapping(for: progress, in: mappings)
        )

        XCTAssertEqual(mapping.trackID, chapters[1].audioTrack?.id)
    }

    func testOpaqueCFICanonicalCursorSelectsOneUnifiedChapter() {
        let chapters = [
            epubChapter(number: 1, start: 0.8, end: 0.96, duration: 100),
            epubChapter(number: 2, start: 0.96, end: 1, duration: 100),
        ]
        let mappings = BookProgressMappingBuilder().build(
            bookID: bookID,
            chapters: chapters,
            readerMode: .paged,
            hasReadableRendition: true
        )

        let chapterID = BookProgressMappingResolver().currentChapterID(
            bookID: bookID,
            chapters: chapters,
            mappings: mappings,
            progress: canonicalProgress(
                index: 9_500,
                location: "epubcfi(/6/144!/4/2/2:10)"
            )
        )

        XCTAssertEqual(chapterID, chapters[0].id)
    }

    func testNativeExactLocationIsTheUnifiedChapterAuthority() {
        let chapters = [
            epubChapter(number: 1, start: 0, end: 0.96, duration: 100),
            epubChapter(number: 2, start: 0.96, end: 1, duration: 100),
        ]
        let mappings = BookProgressMappingBuilder().build(
            bookID: bookID,
            chapters: chapters,
            readerMode: .paged,
            hasReadableRendition: true
        )
        let location = """
            {"href":"Text/chapter-2.xhtml","locations":{"progression":0.1}}
            """

        let chapterID = BookProgressMappingResolver().currentChapterID(
            bookID: bookID,
            chapters: chapters,
            mappings: mappings,
            progress: canonicalProgress(index: 9_500, location: location)
        )

        XCTAssertEqual(chapterID, chapters[1].id)
    }

    func testSameBookCursorOutsideMappedRangesDoesNotInventAnAudioChapter() {
        let track = musicTrack(number: 1, duration: 100)
        let chapter = BookChapterMapping(
            id: "chapter-1",
            title: "Chapter 1",
            order: 0,
            depth: 0,
            readTarget: .epub(location: "Text/chapter-1.xhtml"),
            readStartFraction: 0.2,
            readEndFraction: 0.4,
            audioTrack: track
        )
        let mapping = BookProgressTrackMapping(
            trackID: track.id,
            currentEntityID: bookID,
            unit: .cfi,
            startIndex: 2_000,
            endIndex: 4_000,
            total: 10_000,
            mode: .paged
        )
        let progress = canonicalProgress(index: 9_000, location: "authoritative-text-position")

        XCTAssertNil(
            BookProgressMappingResolver().mapping(for: progress, in: [mapping])
        )
        XCTAssertNil(
            BookProgressMappingResolver().currentChapterID(
                bookID: bookID,
                chapters: [chapter],
                mappings: [mapping],
                progress: progress
            )
        )
        XCTAssertNil(
            BookProgressMappingResolver().legacyProgressPromotionRequest(
                tracks: [track],
                mappings: [mapping],
                legacyResumeSeconds: 50,
                progress: progress
            )
        )
    }

    func testLegacyAbsoluteResumePromotesAFartherCanonicalPosition() throws {
        let chapters = [
            epubChapter(number: 1, start: 0, end: 0.5, duration: 100),
            epubChapter(number: 2, start: 0.5, end: 1, duration: 100),
        ]
        let mappings = BookProgressMappingBuilder().build(
            bookID: bookID,
            chapters: chapters,
            readerMode: .paged,
            hasReadableRendition: true
        )

        let request = try XCTUnwrap(
            BookProgressMappingResolver().legacyProgressPromotionRequest(
                tracks: chapters.compactMap(\.audioTrack),
                mappings: mappings,
                legacyResumeSeconds: 175,
                progress: canonicalProgress(index: 4_000, location: "exact-text-position")
            )
        )

        XCTAssertEqual(request.currentEntityID, bookID)
        XCTAssertEqual(request.index, 8_750)
        XCTAssertNil(request.location)
    }

    func testLegacyResumeDoesNotMoveAFartherReadablePositionBackward() {
        let chapters = [
            epubChapter(number: 1, start: 0, end: 0.5, duration: 100),
            epubChapter(number: 2, start: 0.5, end: 1, duration: 100),
        ]
        let mappings = BookProgressMappingBuilder().build(
            bookID: bookID,
            chapters: chapters,
            readerMode: .paged,
            hasReadableRendition: true
        )

        XCTAssertNil(
            BookProgressMappingResolver().legacyProgressPromotionRequest(
                tracks: chapters.compactMap(\.audioTrack),
                mappings: mappings,
                legacyResumeSeconds: 175,
                progress: canonicalProgress(index: 9_000, location: "farther-text-position")
            )
        )
    }

    func testLegacyResumePreservesAnUnmatchedReadableCursor() {
        let chapters = [
            epubChapter(number: 1, start: 0, end: 0.5, duration: 100),
            epubChapter(number: 2, start: 0.5, end: 1, duration: 100),
        ]
        let mappings = BookProgressMappingBuilder().build(
            bookID: bookID,
            chapters: chapters,
            readerMode: .paged,
            hasReadableRendition: true
        )
        let unmatched = EntityProgressCapability(
            currentEntityID: UUID(uuidString: "00000000-0000-0000-0000-000000000077"),
            unit: .page,
            index: 8,
            total: 20,
            mode: .paged,
            completedAt: nil,
            updatedAt: nil,
            workIndex: 8,
            workTotal: 20,
            location: "unmatched-readable-position"
        )

        XCTAssertNil(
            BookProgressMappingResolver().legacyProgressPromotionRequest(
                tracks: chapters.compactMap(\.audioTrack),
                mappings: mappings,
                legacyResumeSeconds: 175,
                progress: unmatched
            )
        )
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

    private func canonicalProgress(index: Int, location: String?) -> EntityProgressCapability {
        EntityProgressCapability(
            currentEntityID: bookID,
            unit: .cfi,
            index: index,
            total: 10_000,
            mode: .paged,
            completedAt: nil,
            updatedAt: nil,
            workIndex: index,
            workTotal: 10_000,
            location: location
        )
    }

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
            audioTrack: musicTrack(number: number, duration: duration)
        )
    }

    private func audioOnlyChapter(number: Int, duration: Double) -> BookChapterMapping {
        BookChapterMapping(
            id: "part-\(number)",
            title: "Part \(number)",
            order: number - 1,
            depth: 0,
            readTarget: nil,
            audioTrack: musicTrack(number: number, duration: duration)
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
