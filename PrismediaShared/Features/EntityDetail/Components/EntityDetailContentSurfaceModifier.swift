import SwiftUI

/// Stable content plane beneath the artwork-driven Entity Detail atmosphere.
/// It intentionally does not clip so focused tvOS content can grow beyond it.
struct EntityDetailContentSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(
            cornerRadius: PrismediaRadius.panel,
            style: .continuous
        )

        content
            .background(PrismediaColor.groupedContentBackground, in: shape)
            .background(PrismediaColor.background, in: shape)
            .overlay {
                shape.stroke(
                    PrismediaColor.borderSubtle,
                    lineWidth: PrismediaLayout.hairline
                )
            }
            .shadow(
                color: .black.opacity(0.12),
                radius: PrismediaSpacing.large,
                y: PrismediaSpacing.small
            )
    }
}

extension View {
    func entityDetailContentSurface() -> some View {
        modifier(EntityDetailContentSurfaceModifier())
    }
}

#if DEBUG
    #Preview("Entity Detail Content Surface") {
        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
            Text("Main")
                .font(.headline)
            Text("A stable reading plane over an artwork-driven background.")
                .foregroundStyle(PrismediaColor.textSecondary)
        }
        .padding(PrismediaSpacing.extraLarge)
        .modifier(EntityDetailContentSurfaceModifier())
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }
#endif
