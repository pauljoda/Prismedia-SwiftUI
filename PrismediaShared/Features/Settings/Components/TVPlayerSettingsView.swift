import SwiftUI

#if os(tvOS)
    struct TVPlayerSettingsView: View {
        let playbackPreferences: VideoPlaybackPreferences

        var body: some View {
            @Bindable var playbackPreferences = playbackPreferences

            TVSettingsSplitLayout(
                title: TVSettingsDestination.player.title,
                description: TVSettingsDestination.player.description
            ) {
                Form {
                    Section {
                        Picker("Playback Engine", selection: $playbackPreferences.engine) {
                            ForEach(VideoPlaybackEngine.allCases) { engine in
                                Text(engine.label).tag(engine)
                            }
                        }
                        .accessibilityIdentifier("tv.settings.playback-engine")
                    } header: {
                        Label("Video Player", systemImage: "play.rectangle")
                    } footer: {
                        Text(playbackPreferences.engine.explanation)
                    }
                }
            }
            .navigationTitle(TVSettingsDestination.player.title)
        }
    }

    #if DEBUG
        #Preview("TV Player Settings") {
            NavigationStack {
                TVPlayerSettingsView(
                    playbackPreferences: VideoPlaybackPreferences(
                        store: InMemoryVideoPlaybackEnginePreferenceStore(engine: .vlc)
                    )
                )
            }
        }
    #endif
#endif
