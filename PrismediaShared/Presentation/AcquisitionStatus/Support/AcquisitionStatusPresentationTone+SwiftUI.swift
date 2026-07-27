import SwiftUI

extension AcquisitionStatusPresentationTone {
    var foregroundStyle: Color {
        switch self {
        case .downloading, .searching: PrismediaColor.accent
        case .queued, .cleanup: PrismediaColor.textSecondary
        case .attention: PrismediaColor.warning
        case .failed: PrismediaColor.destructive
        case .done: PrismediaColor.success
        case .muted, .wanted: PrismediaColor.textMuted
        }
    }
}
