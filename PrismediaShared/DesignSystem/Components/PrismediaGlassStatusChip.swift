import SwiftUI

struct PrismediaGlassStatusChip: View {
    let title: String?
    let systemImage: String?
    let tint: Color?
    let size: PrismediaGlassStatusChipSize
    let iconAfterTitle: Bool

    init(
        _ title: String?,
        systemImage: String? = nil,
        tint: Color? = nil,
        size: PrismediaGlassStatusChipSize = .standard,
        iconAfterTitle: Bool = false
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.size = size
        self.iconAfterTitle = iconAfterTitle
    }

    var body: some View {
        Group {
            switch size {
            case .thumbnail:
                chipContent
                    .padding(.horizontal, PrismediaSpacing.extraSmall)
                    .padding(.vertical, PrismediaSpacing.extraExtraSmall)
                    .glassEffect(
                        glass,
                        in: .rect(cornerRadius: PrismediaRadius.badge)
                    )
            case .standard:
                chipContent
                    .padding(.horizontal, PrismediaSpacing.small)
                    .padding(.vertical, PrismediaSpacing.extraSmall)
                    .frame(minHeight: PrismediaSpacing.extraExtraLarge)
                    .glassEffect(glass, in: .capsule)
            }
        }
        .font(size.font)
        .accessibilityElement(children: .combine)
    }

    private var glass: Glass {
        tint.map { Glass.regular.tint($0) } ?? .regular
    }

    private var chipContent: some View {
        HStack(spacing: PrismediaSpacing.extraSmall) {
            if iconAfterTitle {
                titleView
                iconView
            } else {
                iconView
                titleView
            }
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if let systemImage {
            Image(systemName: systemImage)
        }
    }

    @ViewBuilder
    private var titleView: some View {
        if let title {
            Text(title)
        }
    }
}

#if DEBUG
    #Preview("Glass Status Chip · Tints and Sizes") {
        ZStack {
            PrismediaBackdrop()

            VStack(spacing: PrismediaSpacing.large) {
                PrismediaGlassStatusChip(
                    "Untinted",
                    systemImage: "circle",
                    size: .thumbnail
                )
                PrismediaGlassStatusChip(
                    "Direct Play",
                    systemImage: "play.rectangle",
                    tint: PrismediaColor.success
                )
                PrismediaGlassStatusChip(
                    "8.7",
                    systemImage: "star.fill",
                    tint: PrismediaColor.spectrumYellow,
                    size: .thumbnail,
                    iconAfterTitle: true
                )
                PrismediaGlassStatusChip(
                    nil,
                    systemImage: "heart.fill",
                    tint: PrismediaColor.destructive,
                    size: .thumbnail
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    #Preview("Glass Status Chip · Bright and Dark Media") {
        HStack(spacing: PrismediaSpacing.section) {
            PrismediaGlassStatusChip(
                "Wanted",
                systemImage: "bookmark.fill",
                tint: PrismediaColor.mediaOverlayGlassTint
            )
            .padding(PrismediaSpacing.extraLarge)
            .background(Color.white)

            PrismediaGlassStatusChip(
                "Wanted",
                systemImage: "bookmark.fill",
                tint: PrismediaColor.mediaOverlayGlassTint
            )
            .padding(PrismediaSpacing.extraLarge)
            .background(Color.black)
        }
    }

    #Preview("Glass Status Chip · Accessibility Type") {
        PrismediaGlassStatusChip(
            "A deliberately long acquisition status",
            systemImage: "arrow.down.circle.fill",
            tint: PrismediaColor.warning
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
