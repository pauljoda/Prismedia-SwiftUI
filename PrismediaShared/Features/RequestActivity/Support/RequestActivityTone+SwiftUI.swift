import SwiftUI

extension RequestActivityTone {
    var foregroundStyle: Color {
        switch self {
        case .downloading: PrismediaColor.accent
        case .searching: PrismediaColor.accent
        case .queued: PrismediaColor.textSecondary
        case .cleanup: PrismediaColor.textSecondary
        case .attention: PrismediaColor.warning
        case .failed: PrismediaColor.destructive
        case .done: PrismediaColor.success
        case .muted: PrismediaColor.textMuted
        }
    }
}
