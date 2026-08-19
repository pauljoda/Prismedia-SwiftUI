import Observation

@Observable
@MainActor
final class VideoPlaybackPreferences {
    var engine: VideoPlaybackEngine {
        didSet { store.save(engine) }
    }

    var vlcNetworkCachingSeconds: Int {
        didSet {
            let normalizedSeconds = VLCNetworkCachingSettings.normalizedSeconds(
                vlcNetworkCachingSeconds
            )
            if vlcNetworkCachingSeconds != normalizedSeconds {
                vlcNetworkCachingSeconds = normalizedSeconds
            }
            vlcNetworkCachingStore.saveSeconds(normalizedSeconds)
        }
    }

    @ObservationIgnored
    private let store: any VideoPlaybackEnginePreferenceStoring
    @ObservationIgnored
    private let vlcNetworkCachingStore: any VLCNetworkCachingPreferenceStoring

    init(
        store: any VideoPlaybackEnginePreferenceStoring = UserDefaultsVideoPlaybackEnginePreferenceStore(),
        vlcNetworkCachingStore: any VLCNetworkCachingPreferenceStoring = UserDefaultsVLCNetworkCachingPreferenceStore()
    ) {
        self.store = store
        self.vlcNetworkCachingStore = vlcNetworkCachingStore
        #if DEBUG
            engine = PrismediaUITestBootstrap.videoPlaybackEngine() ?? store.load()
        #else
            engine = store.load()
        #endif
        vlcNetworkCachingSeconds = vlcNetworkCachingStore.loadSeconds()
    }
}
