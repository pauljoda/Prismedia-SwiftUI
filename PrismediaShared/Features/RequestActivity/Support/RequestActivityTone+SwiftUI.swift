import SwiftUI

extension RequestActivityTone {
    var foregroundStyle: Color {
        switch self {
        case .downloading: PrismediaColor.accent
        case .searching: PrismediaColor.accent
        case .queued: PrismediaColor.textSecondary
        case .cleanup: PrismediaColor.textSecondary
        case .attention: .orange
        case .failed: .red
        case .done: .green
        case .muted: PrismediaColor.textMuted
        }
    }
}
