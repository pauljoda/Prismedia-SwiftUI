import SwiftUI

/// Opaque semantic surface for substantial content groupings.
public struct PrismediaPanelModifier: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        let shape = RoundedRectangle(
            cornerRadius: PrismediaRadius.panel,
            style: .continuous
        )

        content
            .background(PrismediaColor.groupedContentBackground, in: shape)
            .background(PrismediaColor.background, in: shape)
            .clipShape(shape)
            .overlay {
                shape.stroke(PrismediaColor.borderSubtle, lineWidth: PrismediaLayout.hairline)
            }
            .shadow(
                color: .black.opacity(0.1),
                radius: PrismediaSpacing.large,
                y: PrismediaSpacing.small
            )
    }
}

extension View {
    public func prismediaPanel() -> some View {
        modifier(PrismediaPanelModifier())
    }
}

#if DEBUG
    #Preview("Content Panel · Dark") {
        Text("Continue watching")
            .font(PrismediaTypography.cardTitle)
            .padding(PrismediaSpacing.large)
            .modifier(PrismediaPanelModifier())
            .padding(PrismediaSpacing.large)
            .background(PrismediaBackdrop())
            .preferredColorScheme(.dark)
    }
#endif
