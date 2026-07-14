enum EntityTranscriptPhase: Equatable, Sendable {
    case idle
    case loading
    case content([EntityTranscriptCue])
    case failure(String)
}
