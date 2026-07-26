import SwiftUI

enum PrismediaSidebarPalette {
    static func accent(for sectionID: String, fallbackIndex: Int) -> Color {
        switch sectionID {
        case "overview": PrismediaColor.materialSpectrumRed
        case "video": PrismediaColor.materialSpectrumOrange
        case "images": PrismediaColor.materialSpectrumYellow
        case "audio": PrismediaColor.materialSpectrumGreen
        case "books": PrismediaColor.materialSpectrumCyan
        case "browse": PrismediaColor.materialSpectrumBlue
        case "operate", "library-management": PrismediaColor.materialSpectrumViolet
        default: PrismediaColor.materialSpectrumColor(at: fallbackIndex)
        }
    }
}
