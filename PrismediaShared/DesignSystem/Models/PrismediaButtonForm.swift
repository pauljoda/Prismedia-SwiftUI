import SwiftUI

enum PrismediaButtonForm: Hashable, Sendable {
    case automatic
    case fill
    case compactIcon

    var buttonBorderShape: ButtonBorderShape {
        switch self {
        case .automatic:
            .automatic
        case .fill:
            .capsule
        case .compactIcon:
            .circle
        }
    }
}
