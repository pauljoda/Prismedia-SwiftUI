import SwiftUI

/// A fixed-radius continuous content shape whose silhouette remains stable as
/// content moves beneath system chrome.
public struct PrismediaStableRoundedRectangle: InsettableShape {
    public let cornerRadius: CGFloat
    private let insetAmount: CGFloat

    public init(cornerRadius: CGFloat) {
        self.cornerRadius = cornerRadius
        insetAmount = 0
    }

    private init(cornerRadius: CGFloat, insetAmount: CGFloat) {
        self.cornerRadius = cornerRadius
        self.insetAmount = insetAmount
    }

    public func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let insetRadius = max(cornerRadius - insetAmount, 0)
        return RoundedRectangle(
            cornerRadius: insetRadius,
            style: .continuous
        )
        .path(in: insetRect)
    }

    public func inset(by amount: CGFloat) -> PrismediaStableRoundedRectangle {
        PrismediaStableRoundedRectangle(
            cornerRadius: cornerRadius,
            insetAmount: insetAmount + amount
        )
    }
}

#if DEBUG
    #Preview("Stable Rounded Rectangle") {
        Text("Stable concentric content shape")
            .padding(PrismediaSpacing.large)
            .background(
                PrismediaColor.elevatedContentBackground,
                in: PrismediaStableRoundedRectangle(cornerRadius: PrismediaRadius.card)
            )
            .padding()
            .preferredColorScheme(.dark)
    }
#endif
