import SwiftUI

#if os(tvOS)
    struct TVPlayerSettingsView: View {
        let playbackPreferences: VideoPlaybackPreferences

        var body: some View {
            TVSettingsSplitLayout(
                title: TVSettingsDestination.player.title,
                description: TVSettingsDestination.player.description
            ) {
                Form {
                    VideoPlaybackEngineSettingsSection(
                        playbackPreferences: playbackPreferences
                    )
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
                        store: InMemoryVideoPlaybackEnginePreferenceStore()
                    )
                )
            }
        }
    #endif
#endif
