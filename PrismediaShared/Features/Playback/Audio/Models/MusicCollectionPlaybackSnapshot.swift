import Foundation

public struct MusicCollectionPlaybackSnapshot: Equatable, Sendable {
    public let sections: [MusicTrackSection]
    public let tracks: [MusicTrack]

    public init(sections: [MusicTrackSection]) {
        self.sections = sections
        tracks = sections.flatMap(\.tracks)
    }
}
