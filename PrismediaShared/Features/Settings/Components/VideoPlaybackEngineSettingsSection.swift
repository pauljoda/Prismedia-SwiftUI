import SwiftUI

struct VideoPlaybackEngineSettingsSection: View {
    let playbackPreferences: VideoPlaybackPreferences

    var body: some View {
        @Bindable var playbackPreferences = playbackPreferences

        Section {
            Picker("Playback Engine", selection: $playbackPreferences.engine) {
                ForEach(VideoPlaybackEngine.userSelectableCases) { engine in
                    Text(engine.label).tag(engine)
                }
            }
            .accessibilityIdentifier(playbackEngineAccessibilityIdentifier)

            #if os(tvOS)
                HStack {
                    Text("VLC Network Cache")
                    Spacer()
                    Button("Decrease Network Cache", systemImage: "minus") {
                        adjustNetworkCachingSeconds(by: -1)
                    }
                    .labelStyle(.iconOnly)
                    .disabled(
                        playbackPreferences.vlcNetworkCachingSeconds
                            <= VLCNetworkCachingSettings.secondsRange.lowerBound
                    )
                    HStack(spacing: 6) {
                        Text(playbackPreferences.vlcNetworkCachingSeconds, format: .number)
                            .monospacedDigit()
                        Text("seconds")
                            .foregroundStyle(.secondary)
                    }
                    .frame(minWidth: 140)
                    Button("Increase Network Cache", systemImage: "plus") {
                        adjustNetworkCachingSeconds(by: 1)
                    }
                    .labelStyle(.iconOnly)
                    .disabled(
                        playbackPreferences.vlcNetworkCachingSeconds
                            >= VLCNetworkCachingSettings.secondsRange.upperBound
                    )
                }
                .accessibilityIdentifier(vlcNetworkCachingAccessibilityIdentifier)
            #else
                Stepper(
                    value: $playbackPreferences.vlcNetworkCachingSeconds,
                    in: VLCNetworkCachingSettings.secondsRange
                ) {
                    LabeledContent("VLC Network Cache") {
                        Text(playbackPreferences.vlcNetworkCachingSeconds, format: .number)
                            .monospacedDigit()
                        Text("seconds")
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityIdentifier(vlcNetworkCachingAccessibilityIdentifier)
            #endif
        } header: {
            Label("Video Player", systemImage: "play.rectangle")
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                Text(playbackPreferences.engine.explanation)
                Text(
                    "Network cache applies only to VLC compatibility playback. Changes take effect the next time a video opens."
                )
            }
        }
    }

    private func adjustNetworkCachingSeconds(by amount: Int) {
        playbackPreferences.vlcNetworkCachingSeconds += amount
    }

    private var playbackEngineAccessibilityIdentifier: String {
        #if os(tvOS)
            "tv.settings.playback-engine"
        #else
            "settings.playback-engine"
        #endif
    }

    private var vlcNetworkCachingAccessibilityIdentifier: String {
        #if os(tvOS)
            "tv.settings.vlc-network-cache"
        #else
            "settings.vlc-network-cache"
        #endif
    }
}

#if DEBUG
    #Preview("Playback Engine Settings") {
        Form {
            VideoPlaybackEngineSettingsSection(
                playbackPreferences: VideoPlaybackPreferences(
                    store: InMemoryVideoPlaybackEnginePreferenceStore(),
                    vlcNetworkCachingStore: InMemoryVLCNetworkCachingPreferenceStore()
                )
            )
        }
    }
#endif
