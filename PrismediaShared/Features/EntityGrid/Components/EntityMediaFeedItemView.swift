import SwiftUI

struct EntityMediaFeedItemView: View {
    @State private var animatedSequence: AnimatedImageSequence?
    @State private var stillImage: Image?
    @State private var isVideoReady = false
    @State private var sourceConsumerID: UUID?

    private let preparedItem: EntityMediaFeedPreparedItem
    private let mediaSequence: EntityMediaSequence
    private let contentLoader: EntityMediaContentLoader
    private let isPlaybackActive: Bool
    private let isPrewarmEligible: Bool
    private let onOpen: (EntityThumbnail, EntityMediaSequence) -> Void
    private let onVisibilityChanged: (Bool) -> Void

    init(
        preparedItem: EntityMediaFeedPreparedItem,
        mediaSequence: EntityMediaSequence,
        contentLoader: EntityMediaContentLoader,
        isPlaybackActive: Bool,
        isPrewarmEligible: Bool,
        onOpen: @escaping (EntityThumbnail, EntityMediaSequence) -> Void,
        onVisibilityChanged: @escaping (Bool) -> Void
    ) {
        self.preparedItem = preparedItem
        self.mediaSequence = mediaSequence
        self.contentLoader = contentLoader
        self.isPlaybackActive = isPlaybackActive
        self.isPrewarmEligible = isPrewarmEligible
        self.onOpen = onOpen
        self.onVisibilityChanged = onVisibilityChanged
    }

    var body: some View {
        Button {
            onOpen(item, mediaSequence)
        } label: {
            EntityThumbnailArtworkFrame(aspectRatio: preparedItem.aspectRatio) {
                mediaSurface
            }
            .frame(maxWidth: .infinity)
            .clipShape(.rect(cornerRadius: EntityMediaFeedLayout.cornerRadius))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .onScrollVisibilityChange(threshold: 0.5) { isVisible in
            onVisibilityChanged(isVisible)
        }
        .task(id: sourceRequestID) {
            await loadSourceMedia(consumerID: sourceRequestID)
        }
        .onAppear {
            activateSourceConsumerIfNeeded()
        }
        .onDisappear {
            onVisibilityChanged(false)
            releaseSourceResources()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Open \(item.title)")
        .accessibilityValue(mediaAccessibilityValue)
        .accessibilityHint("Opens the full-screen image viewer")
        .accessibilityIdentifier("entity.feed.media.\(item.id.uuidString)")
    }

    private var item: EntityThumbnail { preparedItem.item }

    private var projection: EntityImageMediaProjection? { preparedItem.projection }

    private var mediaSurface: some View {
        ZStack {
            RemotePosterImage(
                path: posterPath,
                fallbackSeed: item.title,
                systemImage: "photo",
                contentMode: .fit
            )

            if let projection, projection.mediaKind == .video,
                let playbackPath = projection.playbackPath
            {
                EntityImageVideoView(
                    entityID: projection.entityID,
                    path: playbackPath,
                    title: projection.title,
                    isPlaybackActive: isPlaybackActive,
                    isPrewarmActive: isPrewarmEligible,
                    contentMode: .fit,
                    interaction: .feed,
                    onReadyChanged: { isVideoReady = $0 }
                )
            } else if let projection, projection.mediaKind == .animatedImage,
                let animatedSequence
            {
                EntityAnimatedImageView(
                    sequence: animatedSequence,
                    title: projection.title,
                    isPlaybackActive: isPlaybackActive,
                    interaction: .feed
                )
            } else if projection?.mediaKind == .stillImage, let stillImage {
                stillImage
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var posterPath: String? {
        projection?.fallbackArtworkPath ?? item.bestCoverPath
    }

    private var sourceRequestID: UUID? {
        guard
            shouldLoadSourceMedia,
            projection?.mediaKind != .video,
            projection?.sourcePath != nil
        else { return nil }
        return sourceConsumerID
    }

    private var shouldLoadSourceMedia: Bool {
        projection?.mediaKind != .video
    }

    private func activateSourceConsumerIfNeeded() {
        guard sourceConsumerID == nil, shouldLoadSourceMedia, projection?.sourcePath != nil else {
            return
        }
        sourceConsumerID = UUID()
    }

    private func loadSourceMedia(consumerID: UUID?) async {
        guard
            let consumerID,
            shouldLoadSourceMedia,
            let mediaKind = projection?.mediaKind,
            mediaKind != .video,
            projection?.sourcePath != nil
        else {
            animatedSequence = nil
            stillImage = nil
            return
        }
        do {
            let data = try await contentLoader.loadSourceData(
                id: item.id,
                consumerID: consumerID
            )
            guard !Task.isCancelled else { return }
            switch mediaKind {
            case .animatedImage:
                let decoded = await Task.detached(priority: .userInitiated) {
                    AnimatedImageSequence.decode(data: data, maximumPixelSize: 2_048)
                }.value
                guard !Task.isCancelled else { return }
                animatedSequence = decoded
                stillImage = nil
            case .stillImage:
                let decoded = await Task.detached(priority: .userInitiated) {
                    EntityImageStillDecoder.decode(data: data, maximumPixelSize: 2_048)
                }.value
                guard !Task.isCancelled else { return }
                animatedSequence = nil
                stillImage = decoded.map { Image(decorative: $0, scale: 1, orientation: .up) }
            case .video:
                break
            }
        } catch is CancellationError {
            return
        } catch {
            animatedSequence = nil
            stillImage = nil
        }
    }

    private func releaseSourceResources() {
        animatedSequence = nil
        stillImage = nil
        let consumerID = sourceConsumerID
        sourceConsumerID = nil
        guard let consumerID else { return }
        Task {
            await contentLoader.cancelSourceLoad(
                id: item.id,
                consumerID: consumerID
            )
        }
    }

    private var mediaAccessibilityValue: String {
        if stillImage != nil { return "Still image loaded" }
        if animatedSequence != nil { return "Animated image loaded" }
        if projection?.mediaKind == .video, projection?.playbackPath != nil {
            return isVideoReady ? "Video ready" : "Video loading"
        }
        return "Loading image"
    }
}

#if DEBUG
    #Preview("Portrait and Landscape Image Feed") {
        let loader = EntityMediaPreviewLoader(
            details: EntityMediaFeedPreviewData.details
        )
        let items = EntityMediaFeedPreviewData.items
        let contentLoader = EntityMediaContentLoader(
            detailLoader: loader,
            sourceLoader: loader,
            retainedItems: items
        )
        PreviewShell(signedIn: true) {
            ScrollView {
                VStack(spacing: EntityMediaFeedLayout.interItemSpacing) {
                    EntityMediaFeedItemView(
                        preparedItem: EntityMediaFeedPreparedItem(
                            item: items[0],
                            projection: EntityMediaFeedPreviewData.details[items[0].id].map(
                                EntityImageMediaProjection.init(detail:)
                            ),
                            aspectRatio: 2.0 / 3.0
                        ),
                        mediaSequence: EntityMediaSequence(items: items),
                        contentLoader: contentLoader,
                        isPlaybackActive: true,
                        isPrewarmEligible: true,
                        onOpen: { _, _ in },
                        onVisibilityChanged: { _ in }
                    )

                    EntityMediaFeedItemView(
                        preparedItem: EntityMediaFeedPreparedItem(
                            item: items[1],
                            projection: EntityMediaFeedPreviewData.details[items[1].id].map(
                                EntityImageMediaProjection.init(detail:)
                            ),
                            aspectRatio: 16.0 / 9.0
                        ),
                        mediaSequence: EntityMediaSequence(items: items),
                        contentLoader: contentLoader,
                        isPlaybackActive: false,
                        isPrewarmEligible: true,
                        onOpen: { _, _ in },
                        onVisibilityChanged: { _ in }
                    )
                }
            }
        }
    }
#endif
