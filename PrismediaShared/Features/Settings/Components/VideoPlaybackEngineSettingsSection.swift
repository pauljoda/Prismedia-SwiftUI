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
        } header: {
            Label("Video Player", systemImage: "play.rectangle")
        } footer: {
            Text(playbackPreferences.engine.explanation)
        }
    }

    private var playbackEngineAccessibilityIdentifier: String {
        #if os(tvOS)
            "tv.settings.playback-engine"
        #else
            "settings.playback-engine"
        #endif
    }
}

#if DEBUG
    #Preview("Playback Engine Settings") {
        Form {
            VideoPlaybackEngineSettingsSection(
                playbackPreferences: VideoPlaybackPreferences(
                    store: InMemoryVideoPlaybackEnginePreferenceStore()
                )
            )
        }
    }
#endif
