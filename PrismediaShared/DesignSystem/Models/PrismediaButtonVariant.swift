import SwiftUI

enum PrismediaButtonVariant: Hashable, Sendable {
    case standard
    case prominent
    case destructive

    var isProminent: Bool {
        self == .prominent
    }

    var isDestructive: Bool {
        self == .destructive
    }

    var buttonRole: ButtonRole? {
        isDestructive ? .destructive : nil
    }
}
