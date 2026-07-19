import Observation

@Observable
@MainActor
final class VideoPlaybackPreferences {
    var engine: VideoPlaybackEngine {
        didSet { store.save(engine) }
    }

    @ObservationIgnored
    private let store: any VideoPlaybackEnginePreferenceStoring

    init(
        store: any VideoPlaybackEnginePreferenceStoring = UserDefaultsVideoPlaybackEnginePreferenceStore()
    ) {
        self.store = store
        #if DEBUG
            engine = PrismediaUITestBootstrap.videoPlaybackEngine() ?? store.load()
        #else
            engine = store.load()
        #endif
    }
}
