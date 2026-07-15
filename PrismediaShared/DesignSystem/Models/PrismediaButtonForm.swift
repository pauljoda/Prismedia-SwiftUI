import SwiftUI

enum PrismediaButtonForm: Hashable, Sendable {
    case automatic
    case fill
    case fillIcon
    case compactIcon

    var buttonBorderShape: ButtonBorderShape {
        switch self {
        case .automatic:
            .automatic
        case .fill, .fillIcon:
            .capsule
        case .compactIcon:
            .circle
        }
    }

    var requiresSystemImage: Bool {
        switch self {
        case .fillIcon, .compactIcon:
            true
        case .automatic, .fill:
            false
        }
    }
}
