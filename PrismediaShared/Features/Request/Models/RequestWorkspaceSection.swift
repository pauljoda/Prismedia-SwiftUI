import Foundation

#if os(iOS) || os(macOS)
    enum RequestWorkspaceSection: Hashable, Identifiable, CaseIterable {
        case discover
        case activity(RequestActivitySection)

        static let allCases: [RequestWorkspaceSection] = [
            .discover,
            .activity(.downloads),
            .activity(.missing),
            .activity(.cutoffUnmet),
            .activity(.history),
        ]

        var id: String {
            switch self {
            case .discover: "discover"
            case .activity(let section): section.id
            }
        }

        var title: String {
            switch self {
            case .discover: "Discover"
            case .activity(let section): section.title
            }
        }

        var systemImage: String {
            switch self {
            case .discover: "sparkle.magnifyingglass"
            case .activity(let section): section.systemImage
            }
        }
    }
#endif
