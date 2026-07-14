import SwiftUI

public struct EntityThumbnailCardView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var titleScale = 1.0
    @State private var containerWidth: CGFloat?

    let item: EntityThumbnail
    let layout: EntityThumbnailLayout
    let preferredWidth: CGFloat?
    let onPreviewHoldChanged: (Bool) -> Void

    public init(
        item: EntityThumbnail,
        layout: EntityThumbnailLayout = .grid,
        preferredWidth: CGFloat? = nil,
        onPreviewHoldChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.item = item
        self.layout = layout
        self.preferredWidth = preferredWidth
        self.onPreviewHoldChanged = onPreviewHoldChanged
    }

    public var body: some View {
        Group {
            if layout == .list {
                cardContent
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.width
                    } action: { width in
                        if containerWidth != width { containerWidth = width }
                    }
            } else {
                cardContent
            }
        }
        .accessibilityElement(children: hasInteractivePreview ? .contain : .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("entity.thumbnail.\(item.id.uuidString)")
    }

    @ViewBuilder
    private var cardContent: some View {
        if let preferredWidth {
            card
                .frame(width: preferredWidth, alignment: .topLeading)
        } else {
            card
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    @ViewBuilder
    private var card: some View {
        Group {
            switch layout {
            case .list:
                listCard
            case .feed, .mediaOnly:
                if cardPresentation.showsTitleOverlay {
                    EntityThumbnailPosterCardView(
                        item: item,
                        layout: layout,
                        preferredWidth: preferredWidth,
                        onPreviewHoldChanged: onPreviewHoldChanged
                    )
                } else {
                    media
                        .prismediaCard(cornerRadius: PrismediaRadius.badge)
                }
            case .grid, .rail, .wall:
                if cardPresentation.usesArtworkExtension {
                    EntityThumbnailLandscapeCardView(
                        item: item,
                        layout: layout,
                        preferredWidth: preferredWidth,
                        onPreviewHoldChanged: onPreviewHoldChanged
                    )
                } else {
                    EntityThumbnailPosterCardView(
                        item: item,
                        layout: layout,
                        preferredWidth: preferredWidth,
                        onPreviewHoldChanged: onPreviewHoldChanged
                    )
                }
            }
        }
    }

    private var listCard: some View {
        ViewThatFits(in: .horizontal) {
            horizontalListCard
            verticalListCard
        }
    }

    private var verticalListCard: some View {
        let titleStyle = EntityThumbnailTitleStyle(layout: .list, width: containerWidth)

        return VStack(alignment: .leading, spacing: 0) {
            media

            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                Text(item.title)
                    .font(.system(size: thumbnailTitleSize(titleStyle) * titleScale, weight: .semibold))
                    .foregroundStyle(PrismediaColor.textPrimary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : titleStyle.lineLimit)

                MetaChipRow(meta: item.meta)
            }
            .padding(.horizontal, titleStyle.horizontalPadding)
            .padding(.vertical, thumbnailTitleVerticalPadding(titleStyle))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .prismediaCard(cornerRadius: PrismediaRadius.badge)
    }

    private var horizontalListCard: some View {
        let titleStyle = EntityThumbnailTitleStyle(layout: .list, width: containerWidth)

        return HStack(spacing: PrismediaSpacing.medium) {
            media
                .containerRelativeFrame(
                    .horizontal,
                    count: item.thumbnailArtworkPresentation.isWide ? 3 : 4,
                    span: 1,
                    spacing: PrismediaSpacing.medium
                )
                .clipShape(RoundedRectangle(cornerRadius: PrismediaRadius.badge, style: .continuous))

            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                Text(item.title)
                    .font(.system(size: titleStyle.fontSize * titleScale, weight: .semibold))
                    .foregroundStyle(PrismediaColor.textPrimary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : titleStyle.lineLimit)

                MetaChipRow(meta: item.meta)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(PrismediaColor.textMuted)
        }
        .padding(PrismediaSpacing.medium)
        .prismediaCard(cornerRadius: PrismediaRadius.badge)
    }

    private var media: some View {
        EntityThumbnailArtworkView(
            item: item,
            layout: layout,
            preferredWidth: preferredWidth,
            onPreviewHoldChanged: onPreviewHoldChanged
        )
    }

    private func thumbnailTitleSize(_ style: EntityThumbnailTitleStyle) -> CGFloat {
        #if os(tvOS)
            max(22, style.fontSize)
        #else
            style.fontSize
        #endif
    }

    private func thumbnailTitleVerticalPadding(_ style: EntityThumbnailTitleStyle) -> CGFloat {
        #if os(tvOS)
            max(12, style.verticalPadding)
        #else
            style.verticalPadding
        #endif
    }

    private var cardPresentation: EntityThumbnailCardPresentation {
        EntityThumbnailCardPresentation(item: item, layout: layout)
    }

    private var hasInteractivePreview: Bool {
        EntityThumbnailPreview(thumbnail: item).hasInteractivePreview
    }

    private func acquisitionLabel(_ value: String) -> String {
        value.replacingOccurrences(of: "-", with: " ").capitalized
    }

    private var accessibilityLabel: String {
        var components = [item.title, item.kind.displayLabel]
        components.append(contentsOf: item.meta.map(\.label))
        if item.isFavorite { components.append("Favorite") }
        if item.isNsfw { components.append("NSFW") }
        if item.isWanted {
            components.append(item.wantedStatus.map { acquisitionLabel($0.rawValue) } ?? "Wanted")
        }
        if item.isOrganized { components.append("Organized") }
        if let rating = item.rating { components.append("\(rating) star rating") }
        return components.joined(separator: ", ")
    }

}

#if DEBUG
    #Preview("Thumbnail States") {
        PreviewShell {
            ScrollView {
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraLarge) {
                    EntityThumbnailCardView(item: PrismediaPreviewData.videos[0], layout: .wall)

                    HStack(alignment: .top, spacing: PrismediaSpacing.large) {
                        EntityThumbnailCardView(item: PrismediaPreviewData.series, layout: .grid)
                        EntityThumbnailCardView(item: PrismediaPreviewData.book, layout: .grid)
                    }

                    EntityThumbnailCardView(item: PrismediaPreviewData.person, layout: .list)
                }
                .padding(PrismediaSpacing.extraLarge)
            }
            .background(PrismediaBackdrop())
        }
    }

    #Preview("Landscape Episode Extension") {
        PreviewShell {
            EntityThumbnailCardView(
                item: EntityThumbnail(
                    id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
                    kind: .video,
                    title: "The Very Long Episode Title That Must Stay Inside Its Card",
                    summary:
                        "A concise episode description continues across two lines without changing the shared card geometry.",
                    parentKind: .videoSeason,
                    sortOrder: 7,
                    coverURL: "/preview/video-1.jpg",
                    meta: [
                        EntityThumbnailMeta(icon: "duration", label: "42 min"),
                        EntityThumbnailMeta(icon: "resolution", label: "4K"),
                    ],
                    hasSourceMedia: true,
                    progress: 0.46
                ),
                layout: .grid,
                preferredWidth: 320
            )
            .padding(PrismediaSpacing.extraLarge)
            .background(PrismediaBackdrop())
        }
    }

    #Preview("Poster Fallback With Title") {
        PreviewShell {
            EntityThumbnailCardView(
                item: EntityThumbnail(
                    id: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
                    kind: .movie,
                    title: "A Movie Without Poster Art"
                ),
                layout: .grid,
                preferredWidth: 180
            )
            .padding(PrismediaSpacing.extraLarge)
            .background(PrismediaBackdrop())
        }
    }

    #Preview("Landscape Accessibility Type") {
        PreviewShell {
            EntityThumbnailCardView(
                item: EntityThumbnail(
                    id: UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")!,
                    kind: .video,
                    title: "Accessible Episode Card",
                    summary: "The title remains identifiable while secondary copy yields at larger text sizes.",
                    parentKind: .videoSeason,
                    sortOrder: 3,
                    coverURL: "/preview/video-2.jpg",
                    hasSourceMedia: true
                ),
                layout: .grid,
                preferredWidth: 360
            )
            .padding(PrismediaSpacing.extraLarge)
            .background(PrismediaBackdrop())
            .environment(\.dynamicTypeSize, .accessibility3)
        }
    }
#endif
