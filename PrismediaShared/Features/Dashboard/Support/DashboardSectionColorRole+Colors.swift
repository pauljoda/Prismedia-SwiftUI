import SwiftUI

extension DashboardSectionColorRole {
    var colors: [Color] {
        switch self {
        case .continueWatching:
            [PrismediaColor.spectrumCyan, PrismediaColor.spectrumViolet]
        case .recent:
            [PrismediaColor.spectrumBlue, PrismediaColor.spectrumMagenta]
        case .video:
            [PrismediaColor.spectrumRed, PrismediaColor.spectrumOrange]
        case .movie:
            [PrismediaColor.spectrumOrange, PrismediaColor.spectrumYellow]
        case .series:
            [PrismediaColor.spectrumYellow, PrismediaColor.spectrumGreen]
        case .gallery:
            [PrismediaColor.spectrumGreen, PrismediaColor.spectrumCyan]
        case .book:
            [PrismediaColor.spectrumCyan, PrismediaColor.spectrumBlue]
        case .image:
            [PrismediaColor.spectrumBlue, PrismediaColor.spectrumViolet]
        case .audio:
            [PrismediaColor.spectrumViolet, PrismediaColor.spectrumMagenta]
        case .collection:
            [PrismediaColor.spectrumMagenta, PrismediaColor.spectrumRed]
        case .people:
            [PrismediaColor.spectrumRed, PrismediaColor.spectrumViolet]
        case .studios:
            [PrismediaColor.spectrumOrange, PrismediaColor.spectrumMagenta]
        case .tags:
            [PrismediaColor.spectrumGreen, PrismediaColor.spectrumYellow]
        }
    }
}
