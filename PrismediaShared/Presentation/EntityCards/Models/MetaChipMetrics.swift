import CoreGraphics

struct MetaChipMetrics: Hashable, Sendable {
    let rowSpacing: CGFloat
    let contentSpacing: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat

    static let compact = MetaChipMetrics(
        rowSpacing: PrismediaSpacing.extraSmall,
        contentSpacing: PrismediaSpacing.extraExtraSmall,
        horizontalPadding: PrismediaSpacing.extraSmall,
        verticalPadding: PrismediaSpacing.extraExtraSmall
    )
}
