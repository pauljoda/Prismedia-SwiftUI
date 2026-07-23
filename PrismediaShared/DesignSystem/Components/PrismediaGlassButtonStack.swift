import SwiftUI

struct PrismediaGlassButtonStack<Content: View>: View {
    let alignment: HorizontalAlignment
    let spacing: CGFloat
    let content: Content

    init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat = PrismediaSpacing.small,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        GlassEffectContainer(spacing: spacing) {
            VStack(alignment: alignment, spacing: spacing) {
                content
            }
        }
    }
}

#if DEBUG
    #Preview("Glass Button Stack · States") {
        ZStack {
            PrismediaBackdrop()

            PrismediaGlassButtonStack {
                PrismediaButton(
                    "Search for Release",
                    systemImage: "magnifyingglass",
                    variant: .prominent,
                    form: .fill,
                    primaryTint: PrismediaColor.spectrumCyan
                ) {}
                PrismediaButton(
                    "Stop Monitoring",
                    systemImage: "bell.slash",
                    variant: .destructive,
                    form: .fill
                ) {}
            }
            .frame(maxWidth: 420)
            .padding(PrismediaSpacing.extraLarge)
        }
        .preferredColorScheme(.dark)
    }

    #Preview("Glass Button Stack · Loading and Accessibility") {
        PrismediaGlassButtonStack {
            PrismediaButton(
                "Search for Release",
                systemImage: "magnifyingglass",
                form: .fill,
                isLoading: true,
                loadingTitle: "Searching…"
            ) {}
            PrismediaButton(
                "A deliberately long secondary action",
                systemImage: "ellipsis",
                form: .fill
            ) {}
        }
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
