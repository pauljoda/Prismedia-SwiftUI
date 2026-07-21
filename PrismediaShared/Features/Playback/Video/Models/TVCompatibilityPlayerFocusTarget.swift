#if os(tvOS)
    enum TVCompatibilityPlayerFocusTarget: Hashable {
        case timeline
        case audio
        case subtitles
        case speed
    }
#endif
