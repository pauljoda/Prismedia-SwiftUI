import Foundation

struct AudiobookContinuationPlanner: Sendable {
    enum Decision: Equatable, Sendable {
        case startOver
        case resumeCurrentPlayer
        case play(AudiobookResumePoint)
        case playFromBeginning
    }

    func decision(
        isCompleted: Bool,
        isCurrentAudiobook: Bool,
        requiresCanonicalProgress: Bool,
        canonicalResume: AudiobookResumePoint?
    ) -> Decision {
        if isCompleted {
            return .startOver
        }
        if requiresCanonicalProgress {
            return canonicalResume.map(Decision.play) ?? .playFromBeginning
        }
        if isCurrentAudiobook {
            return .resumeCurrentPlayer
        }
        return canonicalResume.map(Decision.play) ?? .playFromBeginning
    }
}
