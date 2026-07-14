import SwiftUI

struct DashboardHeroActionsView: View {
    let presentation: DashboardHeroPresentation
    let primaryTint: Color
    let onNavigate: (EntityLink) -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PrismediaSpacing.small) {
                actions
            }
            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                actions
            }
        }
    }

    private var actions: some View {
        Group {
            PrismediaButton(
                presentation.primaryActionTitle,
                systemImage: "play.fill",
                variant: .prominent,
                primaryTint: primaryTint
            ) {
                onNavigate(presentation.playLink)
            }
            .font(.subheadline.weight(.bold))
            .accessibilityHint("Starts playback")
            .accessibilityIdentifier("dashboard.hero.play")

            PrismediaButton("Details", systemImage: "info.circle", form: .compactIcon) {
                onNavigate(presentation.detailsLink)
            }
            .font(.subheadline.weight(.semibold))
            .accessibilityHint("Opens details for \(presentation.item.title)")
            .accessibilityIdentifier("dashboard.hero.details")
        }
    }
}

#if DEBUG
    #Preview("Dashboard Hero Actions") {
        DashboardHeroActionsView(
            presentation: DashboardHeroPresentation(item: PrismediaPreviewData.videos[0]),
            primaryTint: PrismediaColor.spectrumCyan,
            onNavigate: { _ in }
        )
        .padding()
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }
#endif
