import SwiftUI

/// Opaque semantic surface for content cards in grids, lists, and rails.
public struct PrismediaCardModifier: ViewModifier {
    private let cornerRadius: CGFloat

    public init(cornerRadius: CGFloat = PrismediaRadius.card) {
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        let shape = PrismediaStableRoundedRectangle(cornerRadius: cornerRadius)

        content
            .background(PrismediaColor.elevatedContentBackground, in: shape)
            .background(PrismediaColor.background, in: shape)
            .clipShape(shape)
            .overlay {
                shape.stroke(PrismediaColor.borderSubtle, lineWidth: PrismediaLayout.hairline)
            }
            .shadow(
                color: .black.opacity(0.08),
                radius: PrismediaSpacing.medium,
                y: PrismediaSpacing.extraSmall
            )
    }
}

extension View {
    public func prismediaCard(
        cornerRadius: CGFloat = PrismediaRadius.card
    ) -> some View {
        modifier(PrismediaCardModifier(cornerRadius: cornerRadius))
    }
}

#if DEBUG
    #Preview("Content Card · Dark") {
        Text("Recently added")
            .padding(PrismediaSpacing.large)
            .modifier(PrismediaCardModifier())
            .padding(PrismediaSpacing.large)
            .background(PrismediaBackdrop())
            .preferredColorScheme(.dark)
    }

    #Preview("Content Card · Accessibility") {
        Text("A longer content card title that can wrap")
            .font(PrismediaTypography.cardTitle)
            .padding(PrismediaSpacing.large)
            .modifier(PrismediaCardModifier())
            .padding(PrismediaSpacing.large)
            .background(PrismediaBackdrop())
            .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
