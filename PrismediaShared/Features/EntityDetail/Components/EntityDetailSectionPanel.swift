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
    let requestActivityService: (any RequestActivityServicing)?
    let transcriptSourceLoader: (any EntityTranscriptSourceLoading)?
    let onAcquisitionMutated: @MainActor () async -> Void
    let onEntityPruned: @MainActor () -> Void

    init(
        presentation: EntityDetailPresentation,
        section: EntityDetailSectionID,
        horizontalPadding: CGFloat,
        ownerLink: EntityLink? = nil,
        acquisitionService: (any EntityAcquisitionServicing)? = nil,
        requestActivityService: (any RequestActivityServicing)? = nil,
        transcriptSourceLoader: (any EntityTranscriptSourceLoading)? = nil,
        onAcquisitionMutated: @escaping @MainActor () async -> Void = {},
        onEntityPruned: @escaping @MainActor () -> Void = {}
    ) {
        self.presentation = presentation
        self.section = section
        self.horizontalPadding = horizontalPadding
        self.ownerLink = ownerLink
        self.acquisitionService = acquisitionService
        self.requestActivityService = requestActivityService
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
                EntityDetailMetadataView(items: presentation.metadata)
            case .markers:
                markersContent
            case .transcript:
                transcriptContent
            case .acquisition:
                EntityAcquisitionPanel(
                    entityID: presentation.detail.id,
                    acquisitionService: acquisitionService,
                    requestActivityService: requestActivityService,
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
                            let cardWidth = relationshipCardWidth(for: item)

                            VStack(spacing: PrismediaSpacing.small) {
                                EntityThumbnailNavigationSurface(
                                    item: item,
                                    layout: .rail,
                                    preferredWidth: cardWidth
                                )

                                if group.kind == .person,
                                    let subtitle = presentation.creditSubtitle(for: item.id)
                                {
                                    EntityDetailCreditSubtitleView(subtitle: subtitle)
                                }
                            }
                            .frame(width: cardWidth)
                        }
                    }
                    .padding(.vertical, PrismediaSpacing.medium)
                }
                .prismediaFocusSection()
            }
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

    private var relationshipCardHeight: Double {
        #if os(tvOS)
            300 / EntityThumbnailCardPresentation.extendedLandscapeAspectRatio
        #else
            176 / EntityThumbnailCardPresentation.extendedLandscapeAspectRatio
        #endif
    }

    private func relationshipCardWidth(for item: EntityThumbnail) -> CGFloat {
        CGFloat(
            EntityThumbnailCardPresentation(item: item, layout: .rail)
                .width(forCardHeight: relationshipCardHeight)
        )
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
