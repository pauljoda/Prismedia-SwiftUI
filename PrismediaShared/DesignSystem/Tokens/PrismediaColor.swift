import SwiftUI

#if os(tvOS)
#elseif canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

/// Semantic color roles for Prismedia's intentionally dark app chrome.
///
/// Feature views consume roles rather than choosing literal values. Immersive
/// media and document content can still own purpose-built presentation colors.
public enum PrismediaColor {
    public static let background = Color.black
    public static let groupedContentBackground = platformSurface1
    public static let elevatedContentBackground = platformSurface2
    public static let controlFill = platformSurface3
    public static let strongControlFill = platformSurface4
    public static let separator = platformSeparator

    public static let accent = assetColor(named: "PrismediaAccent")
    public static let spectrumRed = Color(red: 1, green: 0.08, blue: 0.12)
    public static let spectrumOrange = Color(red: 1, green: 0.34, blue: 0.04)
    public static let spectrumYellow = Color(red: 1, green: 0.78, blue: 0.12)
    public static let spectrumGreen = Color(red: 0.12, green: 0.76, blue: 0.28)
    public static let spectrumCyan = Color(red: 0.04, green: 0.7, blue: 0.9)
    public static let spectrumBlue = Color(red: 0.05, green: 0.28, blue: 1)
    public static let spectrumViolet = Color(red: 0.48, green: 0.08, blue: 0.96)
    public static let spectrumMagenta = Color(red: 0.84, green: 0.05, blue: 0.88)

    public static let destructive = Color.red
    public static let warning = spectrumOrange
    public static let success = spectrumGreen
    public static let info = spectrumCyan
    public static let onAccent = Color.black
    public static let onMedia = Color.white

    public static let textPrimary = Color.primary
    public static let textSecondary = Color.secondary
    public static let textMuted = platformTertiaryLabel
    public static let border = separator
    public static let borderSubtle = separator.opacity(0.62)

    #if os(tvOS)
        // tvOS presents media in a consistently dark system environment and does
        // not expose the iOS system-background color family.
        private static let platformSurface1 = Color.white.opacity(0.07)
        private static let platformSurface2 = Color.white.opacity(0.1)
        private static let platformSurface3 = Color.white.opacity(0.14)
        private static let platformSurface4 = Color.white.opacity(0.18)
        private static let platformTertiaryLabel = Color.secondary
        private static let platformSeparator = Color.white.opacity(0.2)
    #elseif canImport(UIKit)
        private static let platformSurface1 = Color(uiColor: .secondarySystemBackground)
        private static let platformSurface2 = Color(uiColor: .tertiarySystemBackground)
        private static let platformSurface3 = Color(uiColor: .secondarySystemFill)
        private static let platformSurface4 = Color(uiColor: .tertiarySystemFill)
        private static let platformTertiaryLabel = Color(uiColor: .tertiaryLabel)
        private static let platformSeparator = Color(uiColor: .separator)
    #elseif canImport(AppKit)
        private static let platformSurface1 = Color(nsColor: .underPageBackgroundColor)
        private static let platformSurface2 = Color(nsColor: .controlBackgroundColor)
        private static let platformSurface3 = Color(nsColor: .unemphasizedSelectedContentBackgroundColor)
        private static let platformSurface4 = Color(nsColor: .selectedContentBackgroundColor).opacity(0.22)
        private static let platformTertiaryLabel = Color(nsColor: .tertiaryLabelColor)
        private static let platformSeparator = Color(nsColor: .separatorColor)
    #else
        private static let platformSurface1 = Color.primary.opacity(0.04)
        private static let platformSurface2 = Color.primary.opacity(0.07)
        private static let platformSurface3 = Color.primary.opacity(0.1)
        private static let platformSurface4 = Color.primary.opacity(0.14)
        private static let platformTertiaryLabel = Color.secondary
        private static let platformSeparator = Color.primary.opacity(0.16)
    #endif

    private static func assetColor(named name: String) -> Color {
        #if SWIFT_PACKAGE
            Color(name, bundle: .module)
        #else
            Color(name)
        #endif
    }
}
