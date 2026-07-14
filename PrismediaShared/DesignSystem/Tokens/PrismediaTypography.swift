import SwiftUI

/// Dynamic Type-aware roles for text presented inside Prismedia content.
/// Navigation titles continue to use the native navigation APIs.
public enum PrismediaTypography {
    public static let screenTitle = Font.title.bold()
    public static let sectionTitle = Font.title3.weight(.semibold)
    public static let subsectionTitle = Font.headline.weight(.semibold)
    public static let cardTitle = Font.subheadline.weight(.semibold)
    public static let body = Font.body
    public static let metadata = Font.subheadline
    public static let caption = Font.caption
    public static let captionEmphasized = Font.caption.weight(.semibold)
    public static let compactCaption = Font.caption2
    public static let compactCaptionEmphasized = Font.caption2.weight(.semibold)
    public static let numericCaption = Font.caption.monospacedDigit()
    public static let badge = Font.caption2.monospaced().weight(.semibold)
}
