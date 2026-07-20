#if DEBUG
    struct InMemoryVideoPlaybackEnginePreferenceStore: VideoPlaybackEnginePreferenceStoring {
        private let engine: VideoPlaybackEngine

        init(engine: VideoPlaybackEngine = .defaultChoice) {
            self.engine = engine
        }

        func load() -> VideoPlaybackEngine { engine }
        func save(_ engine: VideoPlaybackEngine) {}
    }
#endif
