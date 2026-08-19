#if DEBUG
    struct InMemoryVLCNetworkCachingPreferenceStore: VLCNetworkCachingPreferenceStoring {
        private let seconds: Int

        init(seconds: Int = VLCNetworkCachingSettings.defaultSeconds) {
            self.seconds = VLCNetworkCachingSettings.normalizedSeconds(seconds)
        }

        func loadSeconds() -> Int { seconds }
        func saveSeconds(_ seconds: Int) {}
    }
#endif
