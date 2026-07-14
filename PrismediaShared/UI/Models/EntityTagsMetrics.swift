import CoreGraphics

struct EntityTagsMetrics: Hashable, Sendable {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat

    static let dense = EntityTagsMetrics(
        horizontalSpacing: PrismediaSpacing.small,
        verticalSpacing: PrismediaSpacing.small,
        horizontalPadding: PrismediaSpacing.medium,
        verticalPadding: PrismediaSpacing.extraSmall
    )
}
