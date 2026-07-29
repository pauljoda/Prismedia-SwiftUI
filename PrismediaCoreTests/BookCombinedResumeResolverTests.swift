import XCTest

@testable import PrismediaCore

final class BookCombinedResumeResolverTests: XCTestCase {
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
