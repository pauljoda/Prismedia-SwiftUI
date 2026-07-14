enum EntityImageMediaInteraction: Hashable, Sendable {
    case viewer
    case feed

    var allowsPlaybackToggle: Bool {
        self == .viewer
    }

    var showsPlaybackControls: Bool {
        self == .viewer
    }

    var showsVideoProgress: Bool {
        true
    }

    var allowsZoom: Bool {
        self == .viewer
    }
}
