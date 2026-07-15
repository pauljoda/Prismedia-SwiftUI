import XCTest

@testable import PrismediaCore

final class BookCombinedResumeResolverTests: XCTestCase {
    func testCurrentListeningPositionMapsToTheMatchingReaderChapterProgression() throws {
        let first = mappedChapter(order: 0, duration: 300)
        let second = mappedChapter(order: 1, duration: 400)

        let target = BookCombinedResumeResolver().resolveReadingTarget(
            chapters: [first, second],
            listening: BookListeningCheckpoint(
                trackID: try XCTUnwrap(second.audioTrack?.id),
                trackOffsetSeconds: 100,
                publicationProgression: 0.6
            )
        )

        XCTAssertEqual(
            target,
            BookReaderLocationTarget(
                location: "Text/chapter-2.xhtml",
                progression: 0.25
            )
        )
    }

    func testTenOfTwentyReadingPagesStartsFiveSecondsBeforeTheAudioMidpoint() throws {
        let chapter = mappedChapter(order: 0, duration: 600)
        let target = try XCTUnwrap(
            BookCombinedResumeResolver().resolveChapter(
                chapter,
                reading: BookReadingCheckpoint(
                    chapterLocation: "Text/chapter-1.xhtml",
                    chapterProgression: 10.0 / 20.0,
                    publicationProgression: 0.25
                ),
                listening: nil
            )
        )

        XCTAssertEqual(target.readingTarget, .savedLocation)
        XCTAssertEqual(target.audioTrackID, chapter.audioTrack?.id)
        XCTAssertEqual(target.audioStartSeconds, 295, accuracy: 0.001)
    }

    func testReadingEstimateInsideTheFirstFiveSecondsStartsAudioAtTheBeginning() throws {
        let chapter = mappedChapter(order: 0, duration: 100)
        let target = try XCTUnwrap(
            BookCombinedResumeResolver().resolveChapter(
                chapter,
                reading: BookReadingCheckpoint(
                    chapterLocation: "Text/chapter-1.xhtml",
                    chapterProgression: 0.04,
                    publicationProgression: 0.01
                ),
                listening: nil
            )
        )

        XCTAssertEqual(target.audioStartSeconds, 0, accuracy: 0.001)
    }

    func testLaterListeningChapterDrivesContinuationAndEstimatesTheReaderPage() throws {
        let first = mappedChapter(order: 0, duration: 300)
        let second = mappedChapter(order: 1, duration: 400)
        let target = try XCTUnwrap(
            BookCombinedResumeResolver().resolveContinuation(
                chapters: [first, second],
                reading: BookReadingCheckpoint(
                    chapterLocation: "Text/chapter-1.xhtml",
                    chapterProgression: 0.9,
                    publicationProgression: 0.45
                ),
                listening: BookListeningCheckpoint(
                    trackID: try XCTUnwrap(second.audioTrack?.id),
                    trackOffsetSeconds: 100,
                    publicationProgression: 0.6
                )
            )
        )

        XCTAssertEqual(
            target.readingTarget,
            .chapter(location: "Text/chapter-2.xhtml", progression: 0.25)
        )
        XCTAssertEqual(target.audioTrackID, second.audioTrack?.id)
        XCTAssertEqual(target.audioStartSeconds, 100, accuracy: 0.001)
    }

    func testLaterReadingChapterWinsEvenWhenListeningHasMoreLocalProgress() throws {
        let first = mappedChapter(order: 0, duration: 300)
        let second = mappedChapter(order: 1, duration: 400)
        let target = try XCTUnwrap(
            BookCombinedResumeResolver().resolveContinuation(
                chapters: [first, second],
                reading: BookReadingCheckpoint(
                    chapterLocation: "Text/chapter-2.xhtml",
                    chapterProgression: 0.1,
                    publicationProgression: 0.55
                ),
                listening: BookListeningCheckpoint(
                    trackID: try XCTUnwrap(first.audioTrack?.id),
                    trackOffsetSeconds: 270,
                    publicationProgression: 0.45
                )
            )
        )

        XCTAssertEqual(target.readingTarget, .savedLocation)
        XCTAssertEqual(target.audioTrackID, second.audioTrack?.id)
        XCTAssertEqual(target.audioStartSeconds, 35, accuracy: 0.001)
    }

    func testChapterCombinedUsesListeningWhenItIsFartherWithinThatChapter() throws {
        let chapter = mappedChapter(order: 0, duration: 200)
        let target = try XCTUnwrap(
            BookCombinedResumeResolver().resolveChapter(
                chapter,
                reading: BookReadingCheckpoint(
                    chapterLocation: "Text/chapter-1.xhtml",
                    chapterProgression: 0.25,
                    publicationProgression: 0.1
                ),
                listening: BookListeningCheckpoint(
                    trackID: try XCTUnwrap(chapter.audioTrack?.id),
                    trackOffsetSeconds: 100,
                    publicationProgression: 0.2
                )
            )
        )

        XCTAssertEqual(
            target.readingTarget,
            .chapter(location: "Text/chapter-1.xhtml", progression: 0.5)
        )
        XCTAssertEqual(target.audioStartSeconds, 100, accuracy: 0.001)
    }

    func testUnstartedChapterCombinedBeginsBothRenditionsAtTheChapterStart() throws {
        let chapter = mappedChapter(order: 0, duration: 200)
        let target = try XCTUnwrap(
            BookCombinedResumeResolver().resolveChapter(
                chapter,
                reading: nil,
                listening: nil
            )
        )

        XCTAssertEqual(
            target.readingTarget,
            .chapter(location: "Text/chapter-1.xhtml", progression: 0)
        )
        XCTAssertEqual(target.audioStartSeconds, 0, accuracy: 0.001)
    }

    func testUnmappedSavedProgressDoesNotSilentlyResetContinuationToTheFirstChapter() {
        let chapter = mappedChapter(order: 0, duration: 200)

        XCTAssertNil(
            BookCombinedResumeResolver().resolveContinuation(
                chapters: [chapter],
                reading: BookReadingCheckpoint(
                    chapterLocation: "Text/unmapped.xhtml",
                    chapterProgression: 0.5,
                    publicationProgression: 0.5
                ),
                listening: nil
            )
        )
    }

    func testListeningCheckpointInsideFirstFiveSecondsRestartsTheChapterAudio() throws {
        let chapter = mappedChapter(order: 0, duration: 200)
        let target = try XCTUnwrap(
            BookCombinedResumeResolver().resolveChapter(
                chapter,
                reading: nil,
                listening: BookListeningCheckpoint(
                    trackID: try XCTUnwrap(chapter.audioTrack?.id),
                    trackOffsetSeconds: 4,
                    publicationProgression: 0.01
                )
            )
        )

        XCTAssertEqual(target.audioStartSeconds, 0, accuracy: 0.001)
    }

    private func mappedChapter(order: Int, duration: Double) -> BookChapterMapping {
        let number = order + 1
        return BookChapterMapping(
            id: "chapter-\(number)",
            title: "Chapter \(number)",
            order: order,
            depth: 0,
            readTarget: .epub(location: "Text/chapter-\(number).xhtml"),
            audioTrack: MusicTrack(
                id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", number))!,
                title: "Chapter \(number)",
                duration: duration,
                sortOrder: order
            ),
            isCurrentReading: false,
            isCurrentAudio: false
        )
    }
}
