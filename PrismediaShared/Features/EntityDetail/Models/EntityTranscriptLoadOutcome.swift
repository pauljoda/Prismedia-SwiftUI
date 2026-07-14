enum EntityTranscriptLoadOutcome: Equatable, Sendable {
    case content([EntityTranscriptCue])
    case failure(String)
    case cancelled
}
