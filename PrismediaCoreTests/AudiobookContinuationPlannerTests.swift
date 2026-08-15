import XCTest

@testable import PrismediaCore

final class AudiobookContinuationPlannerTests: XCTestCase {
    func testCombinedBookUsesCanonicalProgressEvenWhenItsPlayerQueueIsCurrent() {
        let resume = AudiobookResumePoint(trackID: UUID(), trackOffsetSeconds: 417)

        let decision = AudiobookContinuationPlanner().decision(
            isCompleted: false,
            isCurrentAudiobook: true,
            requiresCanonicalProgress: true,
            canonicalResume: resume
        )

        XCTAssertEqual(decision, .play(resume))
    }

    func testAudioOnlyBookCanResumeItsCurrentPlayerQueue() {
        let decision = AudiobookContinuationPlanner().decision(
            isCompleted: false,
            isCurrentAudiobook: true,
            requiresCanonicalProgress: false,
            canonicalResume: nil
        )

        XCTAssertEqual(decision, .resumeCurrentPlayer)
    }
}
