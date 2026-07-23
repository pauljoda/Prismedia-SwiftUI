import SwiftUI

struct PrismediaGlassButtonGroup<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(
        spacing: CGFloat = PrismediaSpacing.small,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        GlassEffectContainer(spacing: spacing) {
            HStack(spacing: spacing) {
                content
            }
        }
    }
}

#if DEBUG
    #Preview("Glass Button Group · States") {
        ZStack {
            PrismediaBackdrop()

            VStack(spacing: PrismediaSpacing.large) {
                PrismediaGlassButtonGroup {
                    PrismediaButton("Refresh", systemImage: "arrow.clockwise") {}
                    PrismediaButton(
                        "Remove",
                        systemImage: "trash",
                        variant: .destructive
                    ) {}
                }

                PrismediaGlassButtonGroup {
                    PrismediaButton(
                        "Continue",
                        systemImage: "arrow.right",
                        variant: .prominent,
                        primaryTint: PrismediaColor.spectrumCyan
                    ) {}
                    PrismediaButton("More", systemImage: "ellipsis") {}
                }
                .disabled(true)
            }
        }
        .preferredColorScheme(.dark)
    }

    #Preview("Glass Button Group · Accessibility") {
        PrismediaGlassButtonGroup {
            PrismediaButton("Search for another release", systemImage: "magnifyingglass") {}
            PrismediaButton("Remove", systemImage: "trash", variant: .destructive) {}
        }
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
