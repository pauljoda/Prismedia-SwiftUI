import SwiftUI

struct DashboardHeroContentView: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    let presentation: DashboardHeroPresentation
    let viewportWidth: CGFloat
    let accent: Color
    let reservesProgressIndicatorSpace: Bool
    let onNavigate: (EntityLink) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            Spacer()
                .frame(height: PrismediaSpacing.medium)
            Text(presentation.item.title)
                .font(PrismediaTypography.screenTitle)
                .foregroundStyle(accent)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .allowsTightening(true)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("dashboard.hero.title")

            DashboardHeroMetadataChipsView(labels: presentation.metadataChips)

            DashboardHeroActionsView(
                presentation: presentation,
                primaryTint: accent,
                onNavigate: onNavigate
            )
        }
        .padding(.horizontal, PrismediaSpacing.large)
        .padding(.top, PrismediaSpacing.small)
        .padding(.bottom, bottomPadding)
        .frame(
            width: min(viewportWidth, PrismediaLayout.readableContentWidth),
            alignment: .leading
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                legibilityGradient
                accessibilityScrim
            }
            .ignoresSafeArea()
        }
    }

    private var legibilityGradient: some View {
        LinearGradient(
            colors: [
                .clear,
                PrismediaColor.background.opacity(0.34),
                PrismediaColor.background.opacity(0.72),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var accessibilityScrim: some View {
        PrismediaColor.background.opacity(
            reduceTransparency
                ? 0.66
                : colorSchemeContrast == .increased ? 0.34 : 0
        )
    }

    private var bottomPadding: CGFloat {
        reservesProgressIndicatorSpace
            ? PrismediaLayout.minimumHitTarget + PrismediaSpacing.small
            : PrismediaSpacing.large
    }
}

#if DEBUG
    #Preview("Dashboard Hero Content · Dark") {
        let presentation = DashboardHeroPresentation(item: PrismediaPreviewData.videos[0])
        DashboardHeroContentView(
            presentation: presentation,
            viewportWidth: 720,
            accent: PrismediaColor.spectrumCyan,
            reservesProgressIndicatorSpace: false,
            onNavigate: { _ in }
        )
        .frame(height: 440)
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }

    #Preview("Dashboard Hero Content · Narrow Long Title") {
        let item = EntityThumbnail(
            id: UUID(uuidString: "D45BEB7B-A24B-40C0-8E9D-360C739FC721")!,
            kind: .movie,
            title: "The Extraordinary Adventures Beyond the Last Visible Horizon",
            meta: [EntityThumbnailMeta(icon: "calendar", label: "2026")],
            hasSourceMedia: true,
            genres: ["Adventure"]
        )
        let presentation = DashboardHeroPresentation(item: item)
        DashboardHeroContentView(
            presentation: presentation,
            viewportWidth: 320,
            accent: PrismediaColor.spectrumCyan,
            reservesProgressIndicatorSpace: false,
            onNavigate: { _ in }
        )
        .frame(width: 320, height: 568)
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }
#endif
