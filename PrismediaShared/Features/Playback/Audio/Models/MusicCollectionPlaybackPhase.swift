enum MusicCollectionPlaybackPhase: Equatable {
    case loading
    case content(MusicCollectionPlaybackSnapshot)
    case empty
    case failure(String)
}
