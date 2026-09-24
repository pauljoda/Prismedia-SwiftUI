import XCTest

@testable import PrismediaCore

final class BookCombinedResumeResolverTests: XCTestCase {
    func testEmbeddedMarkerOffsetSelectsTheReadableChapterWithinOneM4B() throws {
        let track = MusicTrack(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            title: "Complete audiobook", duration: 300, sortOrder: 0
        )
        let chapters = [
            BookChapterMapping(id: "one", title: "One", order: 0, depth: 0,
                readTarget: .epub(location: "Text/one.xhtml"), audioTrack: track,
                audioStartSeconds: 0, audioEndSeconds: 100),
            BookChapterMapping(id: "two", title: "Two", order: 1, depth: 0,
                readTarget: .epub(location: "Text/two.xhtml"), audioTrack: track,
                audioStartSeconds: 100, audioEndSeconds: 300),
        ]

        let target = try XCTUnwrap(BookCombinedResumeResolver().resolveReadingTarget(
            chapters: chapters, trackID: track.id, trackOffsetSeconds: 150
        ))
        XCTAssertEqual(target.location, "Text/two.xhtml")
        XCTAssertEqual(target.progression, 0.25, accuracy: 0.001)
    }

    func testCanonicalCursorResumesBothRenditionsInTheSameChapter() throws {
        let chapters = [
            mappedChapter(order: 0, duration: 300, startFraction: 0, endFraction: 0.5),
            mappedChapter(order: 1, duration: 400, startFraction: 0.5, endFraction: 1),
        ]
        let mappings = BookProgressMappingBuilder().build(
            bookID: bookID,
            chapters: chapters,
            readerMode: .paged,
            hasReadableRendition: true
        )
        let progress = canonicalProgress(index: 6_250, location: nil)

        let target = try XCTUnwrap(
            BookCombinedResumeResolver().resolveContinuation(
                chapters: chapters,
                mappings: mappings,
                progress: progress
            )
        )

        XCTAssertEqual(
            target.readingTarget,
            .chapter(location: "Text/chapter-2.xhtml", progression: 0.25)
        )
        XCTAssertEqual(target.audioTrackID, chapters[1].audioTrack?.id)
        XCTAssertEqual(target.audioStartSeconds, 95, accuracy: 0.001)
    }

    func testExactReadableLocationIsPreservedWhileAudioUsesItsMappedRunway() throws {
        let chapter = mappedChapter(
            order: 0,
            duration: 600,
            startFraction: 0,
            endFraction: 1
        )
        let mappings = BookProgressMappingBuilder().build(
            bookID: bookID,
            chapters: [chapter],
            readerMode: .paged,
            hasReadableRendition: true
        )

        let savedLocation = """
            {
              "href": "Text/chapter-1.xhtml",
              "locations": { "progression": 0.5 }
            }
            """
        let target = try XCTUnwrap(
            BookCombinedResumeResolver().resolveContinuation(
                chapters: [chapter],
                mappings: mappings,
                progress: canonicalProgress(index: 5_000, location: savedLocation)
            )
        )

        XCTAssertEqual(target.readingTarget, .savedLocation(savedLocation))
        XCTAssertEqual(target.audioStartSeconds, 295, accuracy: 0.001)
    }

    func testExactReadableLocationOverridesCoarseChapterBoundaryForAudioResume() throws {
        let chapter = mappedChapter(
            order: 0,
            duration: 600,
            startFraction: 0.4,
            endFraction: 0.6
        )
        let mappings = BookProgressMappingBuilder().build(
            bookID: bookID,
            chapters: [chapter],
            readerMode: .paged,
            hasReadableRendition: true
        )
        let savedLocation = "Text/chapter-1.xhtml#prismedia-progress=0.25"

        let target = try XCTUnwrap(
            BookCombinedResumeResolver().resolveContinuation(
                chapters: [chapter],
                mappings: mappings,
                progress: canonicalProgress(index: 4_000, location: savedLocation)
            )
        )

        XCTAssertEqual(target.readingTarget, .savedLocation(savedLocation))
        XCTAssertEqual(target.audioStartSeconds, 145, accuracy: 0.001)
    }

    func testOpaqueFoliateCFIFallsBackToMappedChapterProgression() throws {
        let chapters = [
            mappedChapter(order: 0, duration: 300, startFraction: 0, endFraction: 0.5),
            mappedChapter(order: 1, duration: 400, startFraction: 0.5, endFraction: 1),
        ]
        let mappings = BookProgressMappingBuilder().build(
            bookID: bookID,
            chapters: chapters,
            readerMode: .paged,
            hasReadableRendition: true
        )

        let target = try XCTUnwrap(
            BookCombinedResumeResolver().resolveContinuation(
                chapters: chapters,
                mappings: mappings,
                progress: canonicalProgress(
                    index: 6_250,
                    location: "epubcfi(/6/4!/4/2/2:14)"
                )
            )
        )

        XCTAssertEqual(
            target.readingTarget,
            .chapter(location: "Text/chapter-2.xhtml", progression: 0.25)
        )
    }

    func testUnstartedBookBeginsBothRenditionsAtTheFirstChapter() throws {
        let chapter = mappedChapter(
            order: 0,
            duration: 200,
            startFraction: 0,
            endFraction: 1
        )
        let mappings = BookProgressMappingBuilder().build(
            bookID: bookID,
            chapters: [chapter],
            readerMode: .paged,
            hasReadableRendition: true
        )

        let target = try XCTUnwrap(
            BookCombinedResumeResolver().resolveContinuation(
                chapters: [chapter],
                mappings: mappings,
                progress: nil
            )
        )

        XCTAssertEqual(
            target.readingTarget,
            .chapter(location: "Text/chapter-1.xhtml", progression: 0)
        )
        XCTAssertEqual(target.audioStartSeconds, 0, accuracy: 0.001)
    }

    func testDifferentChapterCursorDoesNotInventAnAudioPosition() {
        let chapter = mappedChapter(
            order: 0,
            duration: 200,
            startFraction: 0,
            endFraction: 0.5
        )
        let mappings = BookProgressMappingBuilder().build(
            bookID: bookID,
            chapters: [chapter],
            readerMode: .paged,
            hasReadableRendition: true
        )

        XCTAssertNil(
            BookCombinedResumeResolver().resolveContinuation(
                chapters: [chapter],
                mappings: mappings,
                progress: EntityProgressCapability(
                    currentEntityID: UUID(uuidString: "00000000-0000-0000-0000-000000000077"),
                    unit: .page,
                    index: 8,
                    total: 20,
                    mode: .paged,
                    completedAt: nil,
                    updatedAt: nil,
                    workIndex: 8,
                    workTotal: 20,
                    location: nil
                )
            )
        )
    }

    func testEntityChapterProgressResumesTheSavedReaderAndMatchingAudio() throws {
        let chapterID = UUID(uuidString: "00000000-0000-0000-0000-000000000099")!
        let chapter = BookChapterMapping(
            id: "chapter-1",
            title: "Chapter 1",
            order: 0,
            depth: 0,
            readTarget: .entityChapter(id: chapterID),
            readPageCount: 20,
            audioTrack: track(number: 1, duration: 200)
        )
        let mappings = BookProgressMappingBuilder().build(
            bookID: bookID,
            chapters: [chapter],
            readerMode: .paged,
            hasReadableRendition: true
        )
        let progress = EntityProgressCapability(
            currentEntityID: chapterID,
            unit: .page,
            index: 10,
            total: 20,
            mode: .paged,
            completedAt: nil,
            updatedAt: nil,
            workIndex: 10,
            workTotal: 20,
            location: nil
        )

        let target = try XCTUnwrap(
            BookCombinedResumeResolver().resolveContinuation(
                chapters: [chapter],
                mappings: mappings,
                progress: progress
            )
        )

        XCTAssertEqual(target.readingTarget, .savedLocation(nil))
        XCTAssertEqual(target.audioStartSeconds, 100.263, accuracy: 0.001)
    }

    func testReadingAfterCompletionWinsWhenItIsTheLatestActivity() throws {
        let track = track(number: 1, duration: 90)
        let chapter = BookChapterMapping(id: "one", title: "One", order: 0, depth: 0,
            readTarget: .epub(location: "Text/one.xhtml"),
            readStartFraction: 0, readEndFraction: 1, audioTrack: track,
            audioStartSeconds: 0, audioEndSeconds: 90)
        let mappings = BookProgressMappingBuilder().build(
            bookID: bookID, chapters: [chapter], readerMode: .paged,
            hasReadableRendition: true
        )
        let progress = try decodedProgress(
            completedAt: "2026-09-24T01:32:57.000Z",
            updatedAt: "2026-09-24T01:45:00.000Z"
        )

        let target = try XCTUnwrap(BookCombinedResumeResolver().resolveLatestContinuation(
            chapters: [chapter], mappings: mappings, progress: progress
        ))
        XCTAssertEqual(target.readingTarget,
            .chapter(location: "Text/one.xhtml", progression: 0.2))
        XCTAssertEqual(target.audioStartSeconds, 13, accuracy: 0.001)
    }

    func testCompletedBookWithoutLaterActivityStartsAtTheFirstPair() throws {
        let track = track(number: 1, duration: 90)
        let chapter = BookChapterMapping(id: "one", title: "One", order: 0, depth: 0,
            readTarget: .epub(location: "Text/one.xhtml"),
            readStartFraction: 0, readEndFraction: 1, audioTrack: track,
            audioStartSeconds: 0, audioEndSeconds: 90)
        let mappings = BookProgressMappingBuilder().build(
            bookID: bookID, chapters: [chapter], readerMode: .paged,
            hasReadableRendition: true
        )
        let progress = try decodedProgress(
            completedAt: "2026-09-24T01:32:57.000Z",
            updatedAt: "2026-09-24T01:30:00.000Z"
        )

        let target = try XCTUnwrap(BookCombinedResumeResolver().resolveLatestContinuation(
            chapters: [chapter], mappings: mappings, progress: progress
        ))
        XCTAssertEqual(target.readingTarget,
            .chapter(location: "Text/one.xhtml", progression: 0))
        XCTAssertEqual(target.audioStartSeconds, 0, accuracy: 0.001)
    }

    private let bookID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    private func decodedProgress(completedAt: String, updatedAt: String) throws -> EntityProgressCapability {
        let json = """
        {
          "currentEntityId": "\(bookID)", "unit": "cfi", "index": 2000, "total": 10000,
          "mode": "paged", "completedAt": "\(completedAt)", "updatedAt": "\(updatedAt)"
        }
        """
        return try PrismediaJSON.decoder().decode(EntityProgressCapability.self, from: Data(json.utf8))
    }

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

    private func mappedChapter(
        order: Int,
        duration: Double,
        startFraction: Double,
        endFraction: Double
    ) -> BookChapterMapping {
        let number = order + 1
        return BookChapterMapping(
            id: "chapter-\(number)",
            title: "Chapter \(number)",
            order: order,
            depth: 0,
            readTarget: .epub(location: "Text/chapter-\(number).xhtml"),
            readStartFraction: startFraction,
            readEndFraction: endFraction,
            audioTrack: track(number: number, duration: duration)
        )
    }

    private func track(number: Int, duration: Double) -> MusicTrack {
        MusicTrack(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", number))!,
            title: "Chapter \(number)",
            duration: duration,
            sortOrder: number - 1
        )
    }
}
