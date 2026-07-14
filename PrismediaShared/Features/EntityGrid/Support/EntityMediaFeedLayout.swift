import CoreGraphics

public struct EntityMediaFeedLayout: Sendable {
    public static let horizontalInset = PrismediaSpacing.small
    public static let interItemSpacing = PrismediaSpacing.small
    public static let cornerRadius = PrismediaRadius.compact

    public static func itemHeight(
        contentWidth: CGFloat,
        aspectRatio: Double
    ) -> CGFloat {
        contentWidth / CGFloat(rowAspectRatio(aspectRatio))
    }

    public static func rowAspectRatio(_ aspectRatio: Double) -> Double {
        guard aspectRatio.isFinite, aspectRatio > 0 else { return 1 }
        return aspectRatio
    }

    public static func aspectRatio(
        pixelWidth: Int?,
        pixelHeight: Int?,
        fallback: Double
    ) -> Double {
        guard let pixelWidth, let pixelHeight, pixelWidth > 0, pixelHeight > 0 else {
            return fallback
        }
        return Double(pixelWidth) / Double(pixelHeight)
    }
}
