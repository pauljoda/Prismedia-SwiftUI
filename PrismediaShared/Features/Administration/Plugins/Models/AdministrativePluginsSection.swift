import Foundation

enum AdministrativePluginsSection: String, CaseIterable, Identifiable, Hashable {
    case installed
    case prismediaCommunity
    case stashCommunity

    var id: String { rawValue }

    var label: String {
        switch self {
        case .installed: "Installed"
        case .prismediaCommunity: "Prismedia Community"
        case .stashCommunity: "Stash Community"
        }
    }

    var systemImage: String {
        switch self {
        case .installed: "checkmark.seal"
        case .prismediaCommunity: "sparkles"
        case .stashCommunity: "film.stack"
        }
    }
}
