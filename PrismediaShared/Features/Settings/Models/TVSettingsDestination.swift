import Foundation

#if os(tvOS)
    enum TVSettingsDestination: String, Hashable {
        case player
        case visibility
        case account

        var title: String {
            switch self {
            case .player: "Player"
            case .visibility: "Content Visibility"
            case .account: "Account"
            }
        }

        var description: String {
            switch self {
            case .player:
                "Choose the playback engine Prismedia uses for movies and episodes on this Apple TV."
            case .visibility:
                "Control which parts of your library can appear while this account is active."
            case .account:
                "Review the active profile or sign out of Prismedia on this Apple TV."
            }
        }

        var systemImageName: String {
            switch self {
            case .player: "play.rectangle"
            case .visibility: "eye"
            case .account: "person.crop.circle"
            }
        }
    }
#endif
