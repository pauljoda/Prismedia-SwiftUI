import Foundation

public enum RequestActivityPrimaryAction: Hashable, Sendable {
    case chooseRelease
    case searchAgain
    case view

    public var title: String {
        switch self {
        case .chooseRelease: "Choose Release"
        case .searchAgain: "Search Again"
        case .view: "View"
        }
    }

    public var systemImage: String {
        switch self {
        case .chooseRelease: "magnifyingglass"
        case .searchAgain: "arrow.clockwise"
        case .view: "eye"
        }
    }
}
