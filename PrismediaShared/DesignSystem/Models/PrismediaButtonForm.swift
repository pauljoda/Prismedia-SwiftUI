import SwiftUI

enum PrismediaButtonForm: Hashable, Sendable {
    case automatic
    case fill
    case fillIcon
    case compactIcon

    var buttonBorderShape: ButtonBorderShape {
        switch self {
        case .automatic:
            .roundedRectangle(radius: PrismediaRadius.compact)
        case .fill, .fillIcon:
            .roundedRectangle(radius: PrismediaRadius.control)
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
