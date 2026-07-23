import SwiftUI

enum PrismediaGlassStatusChipSize: Hashable, Sendable {
    case thumbnail
    case standard

    var font: Font {
        switch self {
        case .thumbnail:
            PrismediaTypography.badge
        case .standard:
            PrismediaTypography.compactCaptionEmphasized
        }
    }
}
