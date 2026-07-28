import SwiftUI

public struct EntityThumbnailCardView: View {
    @Environment(\.entityThumbnailShowsText) private var showsThumbnailText
    @ScaledMetric(relativeTo: .body) private var compactWidthScale: CGFloat = 1

    let item: EntityThumbnail
    let layout: EntityThumbnailLayout
    let preferredWidth: CGFloat?
    let subtitle: String?
    let subtitleLineLimit: Int?
    let artworkPathOverride: String?
    let onPreviewHoldChanged: (Bool) -> Void
    let onArtworkAction: (() -> Void)?
    let artworkActionHint: String?

    public init(
        item: EntityThumbnail,
        layout: EntityThumbnailLayout = .grid,
        preferredWidth: CGFloat? = nil,
        subtitle: String? = nil,
        subtitleLineLimit: Int? = 1,
        artworkPathOverride: String? = nil,
        onPreviewHoldChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.item = item
        self.layout = layout
        self.preferredWidth = preferredWidth
        self.subtitle = subtitle
        self.subtitleLineLimit = subtitleLineLimit
        self.artworkPathOverride = artworkPathOverride
        self.onPreviewHoldChanged = onPreviewHoldChanged
        onArtworkAction = nil
        artworkActionHint = nil
    }

    init(
        item: EntityThumbnail,
        layout: EntityThumbnailLayout,
        preferredWidth: CGFloat?,
        subtitle: String? = nil,
        subtitleLineLimit: Int? = 1,
        artworkPathOverride: String? = nil,
        onPreviewHoldChanged: @escaping (Bool) -> Void,
        onArtworkAction: @escaping () -> Void,
        artworkActionHint: String
    ) {
        self.item = item
        self.layout = layout
        self.preferredWidth = preferredWidth
        self.subtitle = subtitle
        self.subtitleLineLimit = subtitleLineLimit
        self.artworkPathOverride = artworkPathOverride
        self.onPreviewHoldChanged = onPreviewHoldChanged
        self.onArtworkAction = onArtworkAction
        self.artworkActionHint = artworkActionHint
    }

    public var body: some View {
        Group {
            if layout == .compact {
                widthConstrainedCard
                    .accessibilityHidden(true)
            } else if onArtworkAction == nil {
                widthConstrainedCard
                    .accessibilityElement(children: hasInteractivePreview ? .contain : .ignore)
                    .accessibilityLabel(accessibilityLabel)
            } else {
                widthConstrainedCard
            }
        }
        .accessibilityIdentifier("entity.thumbnail.\(item.id.uuidString)")
    }

    @ViewBuilder
    private var widthConstrainedCard: some View {
        if let renderedWidth {
            card.frame(width: renderedWidth, alignment: .topLeading)
        } else {
            card.frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    @ViewBuilder
    private var card: some View {
        switch layout {
        case .compact:
            artworkCard
        case .list:
            if showsThumbnailText {
                listCard
            } else {
                artworkCard
            }
        case .grid, .rail, .wall, .feed, .mediaOnly:
            if showsThumbnailText {
                captionedCard
            } else {
                artworkCard
            }
        }
    }

    private var captionedCard: some View {
        VStack(alignment: .leading, spacing: artworkCaptionSpacing) {
            artworkSurface

            EntityThumbnailCaptionView(
                item: item,
                subtitle: subtitle,
                subtitleLineLimit: subtitleLineLimit
            )
                .accessibilityHidden(onArtworkAction != nil)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var artworkSurface: some View {
        if let onArtworkAction {
            Button(action: onArtworkAction) {
                artworkCard
                    .contentShape(.rect)
            }
            .prismediaEntityNavigationButtonStyle()
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(artworkActionHint ?? "")
        } else {
            artworkCard
        }
    }

    private var artworkCard: some View {
        artwork
            .prismediaCard(cornerRadius: artworkCornerRadius)
    }

    private var listCard: some View {
        ViewThatFits(in: .horizontal) {
            horizontalListCard
            verticalListCard
        }
    }

    private var verticalListCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            artwork
            EntityThumbnailCaptionView(
                item: item,
                subtitle: subtitle,
                subtitleLineLimit: subtitleLineLimit
            )
        }
        .prismediaCard(cornerRadius: PrismediaRadius.badge)
    }

    private var horizontalListCard: some View {
        HStack(spacing: PrismediaSpacing.medium) {
            artwork
                .containerRelativeFrame(
                    .horizontal,
                    count: item.thumbnailArtworkPresentation.isWide ? 3 : 4,
                    span: 1,
                    spacing: PrismediaSpacing.medium
                )
                .compositingGroup()
                .clipShape(.rect(cornerRadius: PrismediaRadius.badge, style: .continuous))

            EntityThumbnailCaptionView(
                item: item,
                subtitle: subtitle,
                subtitleLineLimit: subtitleLineLimit,
                horizontalPadding: 0
            )
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(PrismediaColor.textMuted)
        }
        .padding(PrismediaSpacing.medium)
        .prismediaCard(cornerRadius: PrismediaRadius.badge)
    }

    private var artwork: some View {
        EntityThumbnailArtworkView(
            item: item,
            layout: layout,
            preferredWidth: renderedWidth,
            artworkPathOverride: artworkPathOverride,
            onPreviewHoldChanged: onPreviewHoldChanged
        )
    }

    private var renderedWidth: CGFloat? {
        guard layout == .compact else { return preferredWidth }
        return preferredWidth.map { $0 * compactWidthScale }
    }

    private var artworkCornerRadius: CGFloat {
        switch layout {
        case .compact: PrismediaRadius.compact
        case .wall, .mediaOnly: 8
        case .grid, .list, .rail, .feed: 6
        }
    }

    private var artworkCaptionSpacing: CGFloat {
        #if os(tvOS)
            PrismediaSpacing.large
        #else
            PrismediaSpacing.small
        #endif
    }

    private var hasInteractivePreview: Bool {
        EntityThumbnailPreview(thumbnail: item).hasInteractivePreview
    }

    private var accessibilityLabel: String {
        var components = [item.title, item.kind.displayLabel]
        if let subtitle = subtitle ?? item.subtitle { components.append(subtitle) }
        components.append(contentsOf: item.meta.map(\.thumbnailAccessibilityLabel))
        if item.isFavorite { components.append("Favorite") }
        if item.isNsfw { components.append("NSFW") }
        if item.isWanted {
            components.append(
                AcquisitionStatusPresentationPolicy.presentation(
                    for: item.wantedStatus ?? item.latestAcquisitionStatus
                ).label
            )
        }
        if item.isOrganized { components.append("Organized") }
        if let rating = item.rating { components.append("\(rating) star rating") }
        return components.joined(separator: ", ")
    }
}

#if DEBUG
    #Preview("Entity Thumbnail · Canonical Caption") {
        PreviewShell {
            HStack(alignment: .top, spacing: PrismediaSpacing.large) {
                EntityThumbnailCardView(
                    item: EntityThumbnail(
                        id: UUID(),
                        kind: .videoSeason,
                        title: "A Very Long Season Title That Must Stay Inside the Card",
                        subtitle: "Example Series",
                        parentKind: .videoSeries,
                        sortOrder: 1,
                        coverURL: "/preview/video-1.jpg",
                        meta: [
                            EntityThumbnailMeta(icon: "episode", label: "12"),
                            EntityThumbnailMeta(icon: "resolution", label: "4K"),
                        ],
                        rating: 4,
                        isNsfw: true
                    ),
                    preferredWidth: 220
                )

                EntityThumbnailCardView(
                    item: PrismediaPreviewData.series,
                    layout: .compact,
                    preferredWidth: 52
                )
            }
            .padding()
            .background(PrismediaBackdrop())
        }
    }

    #Preview("Entity Thumbnail · Artwork Only") {
        PreviewShell {
            EntityThumbnailCardView(
                item: PrismediaPreviewData.videos[0],
                preferredWidth: 260
            )
            .environment(\.entityThumbnailShowsText, false)
            .padding()
            .background(PrismediaBackdrop())
        }
    }
#endif
