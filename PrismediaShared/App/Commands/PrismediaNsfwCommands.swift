#if os(iOS) || os(macOS)
    import SwiftUI

    @MainActor
    struct PrismediaNsfwCommands: Commands {
        let environment: PrismediaAppEnvironment

        var body: some Commands {
            CommandMenu("Content") {
                Button(
                    environment.allowsNsfwContent ? "Use SFW Mode" : "Show NSFW Content",
                    systemImage: environment.allowsNsfwContent ? "shield.fill" : "flame.fill"
                ) {
                    environment.setAllowsNsfwContent(!environment.allowsNsfwContent)
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(environment.session?.user.allowNsfw != true)
                .accessibilityIdentifier("commands.toggle-nsfw")
            }
        }
    }
#endif
