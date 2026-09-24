import XCTest

@testable import PrismediaCore

final class EPUBExactLocationTrackerTests: XCTestCase {
    private let chapterKey = "OEBPS/Text/chapter-2.xhtml"
    private let seven = EPUBParagraphAnchor(index: 7, text: "Paragraph seven.")
    private let eight = EPUBParagraphAnchor(index: 8, text: "Paragraph eight.")
    private let nine = EPUBParagraphAnchor(index: 9, text: "Paragraph nine.")
    private let twelve = EPUBParagraphAnchor(index: 12, text: "Paragraph twelve.")

    func testClosingWithoutMovingKeepsTheRestoredLocation() throws {
        let saved = try exactLocation(nine, progression: 0.4)
        var tracker = EPUBExactLocationTracker()

        XCTAssertTrue(tracker.beginRestore(of: saved, in: chapterKey))
        XCTAssertEqual(tracker.restoreAnchor(in: chapterKey), nine)
        tracker.finishRestore(in: chapterKey, landing: viewport(nine, x: 1_200))

        XCTAssertEqual(tracker.close(), saved)
    }

    func testProgrammaticSettleAfterRestoreIsIgnored() throws {
        let saved = try exactLocation(nine, progression: 0.4)
        var tracker = EPUBExactLocationTracker()
        tracker.beginRestore(of: saved, in: chapterKey)

        XCTAssertNil(tracker.recordLocation(pageLocation(0.38), in: chapterKey))
        tracker.finishRestore(in: chapterKey, landing: viewport(nine, x: 1_200))
        let settle = try XCTUnwrap(tracker.recordLocation(pageLocation(0.4), in: chapterKey))
        // The settled page measures an earlier paragraph; the restored one stays.
        XCTAssertFalse(tracker.recordCapture(viewport(seven, x: 1_200), for: settle))

        XCTAssertEqual(tracker.acceptedLocation, saved)
        XCTAssertEqual(tracker.close(), saved)
    }

    func testReaderMovementAfterRestoreIsAccepted() throws {
        var tracker = try restoredTracker(at: nine, landingX: 1_200)

        tracker.recordUserInput()
        let turn = try XCTUnwrap(tracker.recordLocation(pageLocation(0.5), in: chapterKey))
        XCTAssertEqual(tracker.acceptedLocation, pageLocation(0.5))
        XCTAssertTrue(tracker.recordCapture(viewport(twelve, x: 1_600), for: turn))
        XCTAssertEqual(anchor(of: tracker.close()), twelve)

        // A page turn without touch input, such as a VoiceOver scroll, shows up as a new offset.
        var assistedTracker = try restoredTracker(at: nine, landingX: 1_200)
        let assistedTurn = try XCTUnwrap(assistedTracker.recordLocation(pageLocation(0.5), in: chapterKey))
        XCTAssertTrue(assistedTracker.recordCapture(viewport(twelve, x: 1_600), for: assistedTurn))
        XCTAssertEqual(anchor(of: assistedTracker.acceptedLocation), twelve)

        // Navigation the reader chose supersedes a restore that has not landed yet.
        var navigatingTracker = EPUBExactLocationTracker()
        navigatingTracker.beginRestore(of: try exactLocation(nine, progression: 0.4), in: chapterKey)
        navigatingTracker.recordNavigation()
        XCTAssertNil(navigatingTracker.restoreAnchor(in: chapterKey))
        let search = try XCTUnwrap(navigatingTracker.recordLocation(pageLocation(0.7), in: chapterKey))
        XCTAssertTrue(navigatingTracker.recordCapture(viewport(twelve, x: 2_000), for: search))
        XCTAssertEqual(anchor(of: navigatingTracker.acceptedLocation), twelve)
    }

    func testScrollingBackIsAccepted() throws {
        var tracker = try restoredTracker(at: nine, landingY: 900)

        tracker.recordUserInput()
        let forward = try XCTUnwrap(tracker.recordLocation(pageLocation(0.45), in: chapterKey))
        tracker.recordCapture(viewport(twelve, y: 1_400), for: forward)
        let back = try XCTUnwrap(tracker.recordLocation(pageLocation(0.35), in: chapterKey))
        XCTAssertTrue(tracker.recordCapture(viewport(eight, y: 700), for: back))
        XCTAssertEqual(anchor(of: tracker.acceptedLocation), eight)

        var backwardTracker = try restoredTracker(at: nine, landingY: 900)
        backwardTracker.recordUserInput()
        let scrolledBack = try XCTUnwrap(backwardTracker.recordLocation(pageLocation(0.35), in: chapterKey))
        XCTAssertTrue(backwardTracker.recordCapture(viewport(eight, y: 700), for: scrolledBack))
        XCTAssertEqual(anchor(of: backwardTracker.close()), eight)
    }

    func testLateCaptureAfterCloseIsDropped() throws {
        var tracker = EPUBExactLocationTracker()
        let request = try XCTUnwrap(tracker.recordLocation(pageLocation(0.4), in: chapterKey))

        XCTAssertEqual(tracker.close(), pageLocation(0.4))
        XCTAssertFalse(tracker.recordCapture(viewport(twelve, x: 1_600), for: request))
        XCTAssertNil(tracker.recordLocation(pageLocation(0.5), in: chapterKey))
        tracker.recordNavigation()
        XCTAssertFalse(tracker.beginRestore(of: try exactLocation(nine, progression: 0.4), in: chapterKey))
        XCTAssertEqual(tracker.acceptedLocation, pageLocation(0.4))
        XCTAssertTrue(tracker.isClosed)
    }

    func testFailedMeasurementsNeverPinOrOverwriteTheSavedLocation() throws {
        let saved = try exactLocation(nine, progression: 0.4)
        var tracker = EPUBExactLocationTracker()
        tracker.beginRestore(of: saved, in: chapterKey)
        tracker.abandonRestore(in: chapterKey)

        let failed = try XCTUnwrap(tracker.recordLocation(pageLocation(0.38), in: chapterKey))
        XCTAssertFalse(tracker.recordCapture(nil, for: failed))
        let settle = try XCTUnwrap(tracker.recordLocation(pageLocation(0.38), in: chapterKey))
        XCTAssertFalse(tracker.recordCapture(viewport(seven, x: 800), for: settle))
        XCTAssertEqual(tracker.acceptedLocation, saved)

        tracker.recordUserInput()
        let turn = try XCTUnwrap(tracker.recordLocation(pageLocation(0.5), in: chapterKey))
        XCTAssertFalse(tracker.recordCapture(nil, for: turn))
        XCTAssertEqual(tracker.close(), pageLocation(0.5))
    }

    func testPagedRoundTripIsStableAcrossReopens() throws {
        // Paragraph 4 spans from page 2 into page 3; paragraph 5 is the first to start on page 3.
        let chapter = PagedChapterGeometry(
            resourceKey: chapterKey,
            pageWidth: 400,
            paragraphStarts: [0, 150, 380, 520, 900, 1_350, 1_500, 1_700]
        )
        var reader = EPUBExactLocationTracker()
        turn(&reader, to: 3, in: chapter)
        var saved = try XCTUnwrap(reader.close())
        let firstAnchor = try XCTUnwrap(anchor(of: saved))
        XCTAssertEqual(firstAnchor.index, 5)

        for _ in 0..<3 {
            var tracker = EPUBExactLocationTracker()
            let savedAnchor = try XCTUnwrap(anchor(of: saved))
            XCTAssertTrue(tracker.beginRestore(of: saved, in: chapter.resourceKey))
            let landingPage = chapter.page(restoring: savedAnchor)
            tracker.finishRestore(in: chapter.resourceKey, landing: chapter.viewport(onPage: landingPage))
            let settle = try XCTUnwrap(tracker.recordLocation(chapter.location(onPage: landingPage), in: chapterKey))
            tracker.recordCapture(chapter.viewport(onPage: landingPage), for: settle)

            turn(&tracker, to: landingPage + 1, in: chapter)
            turn(&tracker, to: landingPage, in: chapter)

            saved = try XCTUnwrap(tracker.close())
            XCTAssertEqual(anchor(of: saved), firstAnchor)
        }
    }

    // MARK: - Fixtures

    private func restoredTracker(
        at anchor: EPUBParagraphAnchor,
        landingX: Double = 0,
        landingY: Double = 0
    ) throws -> EPUBExactLocationTracker {
        var tracker = EPUBExactLocationTracker()
        tracker.beginRestore(of: try exactLocation(anchor, progression: 0.4), in: chapterKey)
        tracker.finishRestore(in: chapterKey, landing: viewport(anchor, x: landingX, y: landingY))
        return tracker
    }

    private func turn(
        _ tracker: inout EPUBExactLocationTracker,
        to page: Int,
        in chapter: PagedChapterGeometry
    ) {
        tracker.recordUserInput()
        guard let request = tracker.recordLocation(chapter.location(onPage: page), in: chapter.resourceKey) else {
            return XCTFail("A page turn must be measured.")
        }
        tracker.recordCapture(chapter.viewport(onPage: page), for: request)
    }

    private func pageLocation(_ progression: Double) -> String {
        #"{"href":"OEBPS/Text/chapter-2.xhtml","locations":{"progression":\#(progression)}}"#
    }

    private func exactLocation(_ anchor: EPUBParagraphAnchor, progression: Double) throws -> String {
        try XCTUnwrap(EPUBParagraphLocator.enriching(pageLocation(progression), with: anchor))
    }

    private func viewport(_ anchor: EPUBParagraphAnchor?, x: Double = 0, y: Double = 0) -> EPUBParagraphViewport {
        EPUBParagraphViewport(anchor: anchor, scrollX: x, scrollY: y)
    }

    private func anchor(of location: String?) -> EPUBParagraphAnchor? {
        location.flatMap(EPUBParagraphLocator.anchor(from:))
    }
}

/// A paged chapter reduced to where each paragraph starts along the horizontal page axis. It
/// follows the reading script's rules: capture anchors the first paragraph that starts on the
/// visible page, and restore turns to the page holding the paragraph start.
private struct PagedChapterGeometry {
    let resourceKey: String
    let pageWidth: Double
    let paragraphStarts: [Double]

    func page(restoring anchor: EPUBParagraphAnchor) -> Int {
        Int((paragraphStarts[anchor.index] / pageWidth).rounded(.down))
    }

    func viewport(onPage page: Int) -> EPUBParagraphViewport {
        let pageLeft = Double(page) * pageWidth
        let index = paragraphStarts.firstIndex { $0 >= pageLeft && $0 < pageLeft + pageWidth }
        return EPUBParagraphViewport(
            anchor: index.map { EPUBParagraphAnchor(index: $0, text: "Paragraph \($0).") },
            scrollX: pageLeft,
            scrollY: 0
        )
    }

    func location(onPage page: Int) -> String {
        let progression = Double(page) * pageWidth / (paragraphStarts.last.map { $0 + pageWidth } ?? pageWidth)
        return #"{"href":"\#(resourceKey)","locations":{"progression":\#(progression)}}"#
    }
}
