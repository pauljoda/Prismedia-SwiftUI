import SwiftUI

extension DashboardSectionColorRole {
    var colors: [Color] {
        switch self {
        case .continueWatching:
            [PrismediaColor.spectrumCyan, PrismediaColor.spectrumViolet]
        case .recent:
            [PrismediaColor.spectrumBlue, PrismediaColor.spectrumMagenta]
        case .entity(let kind):
            PrismediaColor.entityAccentPair(for: kind)
        }
    }
}
