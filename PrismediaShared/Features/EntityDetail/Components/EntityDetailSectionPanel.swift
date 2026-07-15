import SwiftUI

struct EntityDetailSectionPanel: View {
    @Environment(\.videoPlaybackSession) private var videoPlaybackSession
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
    @Environment(\.artworkSecondaryText) private var artworkSecondaryText
    let presentation: EntityDetailPresentation
    let section: EntityDetailSectionID
    let horizontalPadding: CGFloat
    let ownerLink: EntityLink?
    let acquisitionService: (any EntityAcquisitionServicing)?
    let transcriptSourceLoader: (any EntityTranscriptSourceLoading)?
    let onAcquisitionMutated: @MainActor () async -> Void
    let onEntityPruned: @MainActor () -> Void

    init(
        presentation: EntityDetailPresentation,
        section: EntityDetailSectionID,
        horizontalPadding: CGFloat,
        ownerLink: EntityLink? = nil,
        acquisitionService: (any EntityAcquisitionServicing)? = nil,
        transcriptSourceLoader: (any EntityTranscriptSourceLoading)? = nil,
        onAcquisitionMutated: @escaping @MainActor () async -> Void = {},
        onEntityPruned: @escaping @MainActor () -> Void = {}
    ) {
        self.presentation = presentation
        self.section = section
        self.horizontalPadding = horizontalPadding
        self.ownerLink = ownerLink
        self.acquisitionService = acquisitionService
        self.transcriptSourceLoader = transcriptSourceLoader
        self.onAcquisitionMutated = onAcquisitionMutated
        self.onEntityPruned = onEntityPruned
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
            switch section {
            case .details:
                detailsContent
            case .metadata:
                metadataContent
            case .markers:
                markersContent
            case .transcript:
                transcriptContent
            case .acquisition:
                EntityAcquisitionPanel(
                    entityID: presentation.detail.id,
                    acquisitionService: acquisitionService,
                    onMutated: onAcquisitionMutated,
                    onEntityPruned: onEntityPruned
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, PrismediaSpacing.medium)
        .accessibilityIdentifier("entity-detail.panel.\(section.rawValue)")
    }

    @ViewBuilder
    private var detailsContent: some View {
        if presentation.detail.relationships.isEmpty,
            EntityDetailReferencedContentPresentation(detail: presentation.detail) == nil
        {
            Text("No related details yet.")
                .foregroundStyle(artworkSecondaryText)
        }

        ForEach(presentation.detail.relationships, id: \.entityDetailGroupID) { group in
            relationshipGroup(group)
                .padding(.bottom, PrismediaSpacing.medium)
                .overlay(alignment: .bottom) {
                    Divider()
                        .overlay(PrismediaColor.borderSubtle)
                }
        }
    }

    @ViewBuilder
    private func relationshipGroup(_ group: EntityGroup) -> some View {
        if group.kind == .tag {
            EntityTags(tags: group.entities, title: group.label)
        } else {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                HStack {
                    sectionTitle(group.label)
                    Spacer()
                    Text(String(group.entities.count))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(artworkSecondaryText)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: relationshipCardSpacing) {
                        ForEach(group.entities) { item in
                            EntityThumbnailNavigationSurface(
                                item: item,
                                layout: .rail,
                                preferredWidth: relationshipCardWidth(for: item.thumbnailPresentationKind)
                            )
                        }
                    }
                    .padding(.vertical, PrismediaSpacing.medium)
                }
                .prismediaFocusSection()
            }
        }
    }

    @ViewBuilder
    private var metadataContent: some View {
        if presentation.metadata.isEmpty {
            placeholder(
                title: "Metadata",
                message: "No metadata is available yet.",
                systemImage: "info.circle"
            )
        } else {
            LazyVGrid(
                columns: [
                    GridItem(
                        .adaptive(minimum: 220),
                        spacing: PrismediaSpacing.extraLarge,
                        alignment: .topLeading
                    )
                ],
                alignment: .leading,
                spacing: 0
            ) {
                ForEach(presentation.metadata) { item in
                    metadataItem(item)
                }
            }
        }
    }

    @ViewBuilder
    private func metadataItem(_ item: EntityDetailMetadataItem) -> some View {
        #if os(tvOS)
            metadataItemContent(item)
        #else
            if let url = item.url {
                Link(destination: url) {
                    metadataItemContent(item)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens in your default browser")
            } else {
                metadataItemContent(item)
            }
        #endif
    }

    private func metadataItemContent(_ item: EntityDetailMetadataItem) -> some View {
        HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
            Image(systemName: item.systemImage)
                .frame(width: 20)
                .foregroundStyle(artworkPrimaryAccent)

            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Text(item.label)
                    .font(.caption)
                    .foregroundStyle(artworkSecondaryText)
                Text(item.value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PrismediaColor.textPrimary)
                    .lineLimit(3)
                if item.url != nil {
                    Label("Open Link", systemImage: "arrow.up.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(artworkPrimaryAccent)
                }
            }
        }
        .padding(.vertical, PrismediaSpacing.medium)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            Divider()
                .overlay(PrismediaColor.borderSubtle)
        }
    }

    private var markersContent: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
            ForEach(presentation.markers, id: \.id) { marker in
                Button {
                    videoPlaybackSession?.activeController?.seek(to: marker.seconds)
                } label: {
                    Label {
                        HStack {
                            Text(marker.title)
                            Spacer()
                            Text(clockTime(marker.seconds))
                                .monospacedDigit()
                        }
                    } icon: {
                        Image(systemName: "bookmark.fill")
                            .foregroundStyle(artworkPrimaryAccent)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(artworkSecondaryText)
                .disabled(!canSeekMarkers)
                .accessibilityLabel("\(marker.title), \(clockTime(marker.seconds))")
                .accessibilityHint(
                    canSeekMarkers
                        ? "Seeks the active video to this marker"
                        : "Start video playback to seek to this marker"
                )
            }
        }
    }

    private var canSeekMarkers: Bool {
        EntityMarkerSeekPolicy.canSeek(
            resolvedVideoID: PlayableVideoResolver.videoID(in: presentation.detail),
            activeVideoID: videoPlaybackSession?.activeVideoDetail?.id
        )
    }

    private var transcriptContent: some View {
        EntityTranscriptView(
            videoID: resolvedVideoID,
            subtitles: presentation.subtitles,
            sourceLoader: transcriptSourceLoader,
            currentTime: ownedPlaybackController?.currentTime,
            onSeek: ownedPlaybackController.map { controller in
                { seconds in controller.seek(to: seconds) }
            }
        )
    }

    private var resolvedVideoID: UUID? {
        PlayableVideoResolver.videoID(in: presentation.detail)
    }

    private var ownedPlaybackController: VideoPlaybackController? {
        guard
            EntityTranscriptSeekPolicy.canSeek(
                ownerLink: ownerLink,
                resolvedVideoID: resolvedVideoID,
                activeOwnerLink: videoPlaybackSession?.activeOwnerLink,
                activeVideoID: videoPlaybackSession?.activeVideoDetail?.id
            )
        else { return nil }
        return videoPlaybackSession?.activeController
    }

    private func placeholder(
        title: String,
        message: String,
        systemImage: String
    ) -> some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(message)
        )
        .frame(maxWidth: .infinity)
    }

    private func sectionTitle(_ value: String) -> some View {
        Text(value)
            .font(.title3.bold())
            .foregroundStyle(PrismediaColor.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    private func clockTime(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private var relationshipCardSpacing: CGFloat {
        #if os(tvOS)
            28
        #else
            12
        #endif
    }

    private func relationshipCardWidth(for kind: EntityKind) -> CGFloat {
        #if os(tvOS)
            kind.prefersWideThumbnail ? 300 : 220
        #else
            kind.prefersWideThumbnail ? 176 : 132
        #endif
    }
}

extension EntityGroup {
    fileprivate var entityDetailGroupID: String {
        code ?? "\(kind.rawValue):\(label)"
    }
}

#if DEBUG
    #Preview("Entity Detail Panel") {
        NavigationStack {
            EntityDetailSectionPanel(
                presentation: EntityDetailPresentation(detail: EntityDetailPreviewFixture.detail),
                section: .details,
                horizontalPadding: PrismediaSpacing.extraLarge
            )
        }
        .padding(.vertical)
    }
#endif
