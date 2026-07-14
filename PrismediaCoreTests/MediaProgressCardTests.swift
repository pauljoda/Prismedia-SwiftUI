import Foundation
import XCTest

@testable import PrismediaCore

final class MediaProgressCardTests: XCTestCase {
    func testKindsUseMediaSpecificPrimaryActions() throws {
        let watch = presentation(kind: .watch)
        let read = presentation(kind: .read)
        let listen = presentation(kind: .listen)

        XCTAssertEqual(try XCTUnwrap(watch.resumeAction).title, "Resume")
        XCTAssertEqual(try XCTUnwrap(watch.resumeAction).systemImage, "play.fill")
        XCTAssertEqual(try XCTUnwrap(read.resumeAction).title, "Continue Reading")
        XCTAssertEqual(try XCTUnwrap(read.resumeAction).systemImage, "book.fill")
        XCTAssertEqual(try XCTUnwrap(listen.resumeAction).title, "Continue Listening")
        XCTAssertEqual(try XCTUnwrap(listen.resumeAction).systemImage, "headphones")
    }

    func testCompletionCopyPreservesWatchingReadingAndListeningSemantics() throws {
        XCTAssertEqual(
            try XCTUnwrap(presentation(kind: .watch).completionAction).title,
            "Mark Watched"
        )
        XCTAssertEqual(
            try XCTUnwrap(presentation(kind: .read).completionAction).title,
            "Mark Read"
        )
        XCTAssertEqual(
            try XCTUnwrap(presentation(kind: .listen).completionAction).title,
            "Mark Listened"
        )

        XCTAssertEqual(
            try XCTUnwrap(presentation(kind: .watch, status: .completed).completionAction).title,
            "Mark Unwatched"
        )
        XCTAssertEqual(
            try XCTUnwrap(presentation(kind: .read, status: .completed).completionAction).title,
            "Mark Unread"
        )
        XCTAssertEqual(
            try XCTUnwrap(presentation(kind: .listen, status: .completed).completionAction).title,
            "Mark Unlistened"
        )
    }

    func testPresentationOnlyExposesActionsRequestedByTheCaller() {
        let presentation = MediaProgressCardPresentation(
            kind: .read,
            status: .inProgress,
            percent: 40,
            showsResume: false,
            showsStartOver: false,
            showsCompletionToggle: false
        )

        XCTAssertNil(presentation.resumeAction)
        XCTAssertNil(presentation.startOverAction)
        XCTAssertNil(presentation.completionAction)
    }

    func testProgressCardUsesProminentPrimaryAndOneCompactSecondaryRow() throws {
        let path = "PrismediaShared/UI/Components/MediaProgressCard.swift"
        let source = try sourceFile(path)

        XCTAssertTrue(source.contains("@Environment(\\.artworkPrimaryAccent)"), path)
        XCTAssertTrue(source.contains("private var primaryAction"), path)
        XCTAssertTrue(source.contains("private var secondaryActions"), path)
        XCTAssertTrue(source.contains("form: .fill"), path)
        XCTAssertTrue(source.contains(".labelStyle(.iconOnly)"), path)
        XCTAssertTrue(source.contains(".buttonStyle(.glass(.clear))"), path)
        XCTAssertTrue(source.contains("GlassEffectContainer("), path)
        XCTAssertTrue(source.contains("PrismediaLayout.minimumHitTarget"), path)
        XCTAssertTrue(source.contains(".accessibilityHint("), path)
        XCTAssertFalse(source.contains("ViewThatFits"), path)
        XCTAssertFalse(source.contains(".prismediaCard("), path)
    }

    func testProgressSummaryKeepsKindStatusPositionAndValueScannable() throws {
        let path = "PrismediaShared/UI/Components/MediaProgressCard.swift"
        let source = try sourceFile(path)

        XCTAssertFalse(source.contains("presentation.progressHeading"), path)
        XCTAssertTrue(source.contains("presentation.statusTitle"), path)
        XCTAssertTrue(source.contains("presentation.positionLabel"), path)
        XCTAssertTrue(source.contains("presentation.contextLabel"), path)
        XCTAssertTrue(source.contains("monospacedDigit()"), path)
        XCTAssertTrue(source.contains("ProgressView(value:"), path)
    }

    private func presentation(
        kind: MediaProgressKind,
        status: MediaProgressStatus = .inProgress
    ) -> MediaProgressCardPresentation {
        MediaProgressCardPresentation(
            kind: kind,
            status: status,
            percent: status == .completed ? 100 : 40,
            positionLabel: "Position",
            contextLabel: "Context",
            showsResume: true,
            showsStartOver: true,
            showsCompletionToggle: true
        )
    }

    private func sourceFile(_ relativePath: String) throws -> String {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appending(path: relativePath),
            encoding: .utf8
        )
    }
}
