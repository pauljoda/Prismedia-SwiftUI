#if os(tvOS)
    enum TVPlaybackOptionsMenu: String, Identifiable {
        case audio
        case subtitles
        case speed

        var id: Self { self }

        var title: String {
            switch self {
            case .audio: "Audio Tracks"
            case .subtitles: "Subtitles"
            case .speed: "Playback Speed"
            }
        }
    }
#endif
