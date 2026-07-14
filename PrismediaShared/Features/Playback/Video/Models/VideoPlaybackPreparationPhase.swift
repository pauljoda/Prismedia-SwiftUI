enum VideoPlaybackPreparationPhase: Equatable, Sendable {
    case idle
    case loading
    case ready
    case failure(String)
}
