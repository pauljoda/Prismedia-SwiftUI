public struct MusicTrackSection: Identifiable, Equatable, Sendable {
    public let title: String?
    public let tracks: [MusicTrack]
    public var id: String { title ?? "tracks" }

    public init(title: String?, tracks: [MusicTrack]) {
        self.title = title
        self.tracks = tracks.filter(\.isPlayable)
    }

    public static func sections(for tracks: [MusicTrack]) -> [Self] {
        let tracks = tracks.filter(\.isPlayable)
        var titles: [String?] = []
        var grouped: [String: [MusicTrack]] = [:]
        for track in tracks {
            let title = track.discTitle
            let key = title ?? ""
            if !titles.contains(where: { $0 == title }) { titles.append(title) }
            grouped[key, default: []].append(track)
        }
        return titles.map { title in
            Self(title: title, tracks: grouped[title ?? "", default: []])
        }
    }
}
