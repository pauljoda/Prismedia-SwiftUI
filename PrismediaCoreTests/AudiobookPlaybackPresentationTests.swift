import Foundation
import XCTest

@testable import PrismediaCore

final class AudiobookPlaybackPresentationTests: XCTestCase {
    func testSavedBookProgressPresentsContinueListening() {
        let presentation = AudiobookPlaybackPresentation(
            totalDuration: 300,
            partCount: 2,
            resumeSeconds: 145,
            isCompleted: false,
            isCurrentAudiobook: false,
            isPlaying: false
        )

        XCTAssertEqual(presentation.actionTitle, "Continue Listening")
        XCTAssertEqual(presentation.progress.percent, 48)
        XCTAssertEqual(presentation.progress.kind, .listen)
        XCTAssertEqual(presentation.progress.positionLabel, "2:25 of 5:00")
        XCTAssertEqual(presentation.progress.contextLabel, "2 parts")
    }

    func testCompletedBookPresentsListenAgainAndListenedState() {
        let presentation = AudiobookPlaybackPresentation(
            totalDuration: 300,
            partCount: 1,
            resumeSeconds: 0,
            isCompleted: true,
            isCurrentAudiobook: false,
            isPlaying: false
        )

        XCTAssertEqual(presentation.actionTitle, "Listen Again")
        XCTAssertEqual(presentation.progress.status, .completed)
        XCTAssertEqual(presentation.progress.percent, 100)
        XCTAssertFalse(presentation.progress.showsResume)
        XCTAssertTrue(presentation.progress.showsStartOver)
    }

    func testCurrentPlayingAudiobookPresentsPause() {
        let presentation = AudiobookPlaybackPresentation(
            totalDuration: 300,
            partCount: 2,
            resumeSeconds: 145,
            isCompleted: false,
            isCurrentAudiobook: true,
            isPlaying: true
        )

        XCTAssertEqual(presentation.actionTitle, "Pause")
        XCTAssertNil(presentation.progress.resumeAction)
    }
}
