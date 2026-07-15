import SwiftUI

@MainActor
struct PrismediaMacCommands: Commands {
    @FocusedValue(MusicPlayerController.self) private var musicPlayer

    let environment: PrismediaAppEnvironment
    let router: PrismediaAppRouter

    var body: some Commands {
        CommandMenu("Navigate") {
            Button("Browse") {
                router.select(tab: .search, availableModes: availableModes)
            }
            .keyboardShortcut("f", modifiers: .command)
            .disabled(environment.session == nil)

            Button("Back") {
                router.navigateBack(in: selectedPathID)
            }
            .keyboardShortcut("[", modifiers: .command)
            .disabled(router.path(for: selectedPathID).isEmpty)

            Divider()

            Button("Dashboard") {
                guard let dashboard = ModeCatalog.overview.destination(id: "dashboard") else { return }
                router.select(mode: ModeCatalog.overview, destination: dashboard)
            }
            .keyboardShortcut("1", modifiers: .command)
            .disabled(environment.session == nil)

            Button("Reload") {
                environment.reloadContent()
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(environment.client == nil)
        }

        CommandMenu("Playback") {
            Button(musicPlayer?.isPlaying == true ? "Pause" : "Play") {
                guard let musicPlayer else { return }
                if musicPlayer.isPlaying {
                    musicPlayer.pause()
                } else {
                    musicPlayer.resume()
                }
            }
            .keyboardShortcut(.space, modifiers: [])
            .disabled(musicPlayer?.currentTrack == nil)

            Button("Previous") {
                musicPlayer?.skipToPrevious()
            }
            .keyboardShortcut(.leftArrow, modifiers: [.command, .option])
            .disabled(musicPlayer?.currentTrack == nil)

            Button("Next") {
                musicPlayer?.skipToNext()
            }
            .keyboardShortcut(.rightArrow, modifiers: [.command, .option])
            .disabled(musicPlayer?.currentTrack == nil)
        }
    }

    private var availableModes: [AppMode] {
        ModeCatalog.modes(for: environment.session?.user)
    }

    private var selectedPathID: String {
        switch router.selectedTab {
        case .search:
            PrismediaAppRouter.searchPathID
        case .destination(let destinationID):
            destinationID
        }
    }
}
