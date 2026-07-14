import SwiftUI

struct EntityImageViewerPage: View {
    @State private var projection: EntityImageMediaProjection?
    @State private var stillImage: Image?
    @State private var animatedSequence: AnimatedImageSequence?
    @State private var exportArtifact: EntityImageExportArtifact?
    @State private var isLoading = false
    @State private var errorMessage: String?

    let item: EntityThumbnail
    let initialDetail: EntityDetail?
    let contentLoader: EntityMediaContentLoader
    let exportStore: EntityImageExportStore
    let isActive: Bool
    let showsControls: Bool

    var body: some View {
        pageSurface
            .toolbar {
                #if os(iOS)
                    if let exportArtifact, showsControls, isActive {
                        ToolbarItem(placement: .bottomBar) {
                            shareLink(exportArtifact)
                        }
                    }
                #elseif os(macOS)
                    if let exportArtifact, showsControls, isActive {
                        ToolbarItem(placement: .primaryAction) {
                            shareLink(exportArtifact)
                        }
                    }
                #endif
            }
    }

    private var pageSurface: some View {
        ZStack {
            switch presentation {
            case .media(let projection):
                media(projection)
            case .loading(let fallbackPath):
                loadingView(fallbackPath: fallbackPath)
            case .fallback(let path):
                fallbackArtwork(path: path)
            case .failure(let message):
                ContentUnavailableView {
                    Label("Couldn’t Open Image", systemImage: "photo.badge.exclamationmark")
                } description: {
                    Text(message)
                } actions: {
                    PrismediaButton("Try Again", variant: .prominent) {
                        Task { await load() }
                    }
                }
                .foregroundStyle(PrismediaColor.onMedia)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: item.id) { await load() }
        .onDisappear { removeExportArtifact() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(pageAccessibilityIdentifier)
    }

    private var presentation: EntityImageViewerPagePresentation {
        EntityImageViewerPagePresentation.resolve(
            projection: projection,
            isLoading: isLoading,
            errorMessage: errorMessage,
            fallbackArtworkPath: projection?.fallbackArtworkPath ?? item.bestCoverPath
        )
    }

    private var pageAccessibilityIdentifier: String {
        guard let projection else {
            return "image-viewer.page.\(item.id.uuidString)"
        }
        switch projection.mediaKind {
        case .video where projection.playbackPath != nil:
            return "image-viewer.media.video"
        case .animatedImage where animatedSequence != nil || stillImage != nil:
            return "image-viewer.media.animated-image"
        case .stillImage where stillImage != nil:
            return "image-viewer.media.still"
        default:
            return "image-viewer.page.\(item.id.uuidString)"
        }
    }

    private func loadingView(fallbackPath: String?) -> some View {
        ZStack {
            if let fallbackPath {
                fallbackArtwork(path: fallbackPath)
            }
            ProgressView("Loading \(item.title)…")
                .tint(PrismediaColor.onMedia)
                .foregroundStyle(PrismediaColor.onMedia)
        }
    }

    @ViewBuilder
    private func media(_ projection: EntityImageMediaProjection) -> some View {
        switch projection.mediaKind {
        case .video:
            if let playbackPath = projection.playbackPath {
                ZStack {
                    fallbackArtwork(path: projection.fallbackArtworkPath ?? item.bestCoverPath)
                    EntityImageVideoView(
                        entityID: projection.entityID,
                        path: playbackPath,
                        title: projection.title,
                        isPlaybackActive: isActive,
                        showsControls: showsControls && isActive
                    )
                }
            } else {
                fallbackArtwork(path: projection.fallbackArtworkPath ?? item.bestCoverPath)
            }
        case .animatedImage:
            if let animatedSequence {
                EntityAnimatedImageView(
                    sequence: animatedSequence,
                    title: projection.title,
                    isPlaybackActive: isActive,
                    showsControls: showsControls && isActive
                )
            } else if let stillImage {
                EntityImageZoomView(
                    image: stillImage,
                    title: projection.title,
                    showsControls: showsControls && isActive
                )
            } else {
                fallbackArtwork(path: projection.fallbackArtworkPath ?? item.bestCoverPath)
            }
        case .stillImage:
            if let stillImage {
                EntityImageZoomView(
                    image: stillImage,
                    title: projection.title,
                    showsControls: showsControls && isActive
                )
            } else {
                fallbackArtwork(path: projection.fallbackArtworkPath ?? item.bestCoverPath)
            }
        }
    }

    private func fallbackArtwork(path: String?) -> some View {
        RemotePosterImage(
            path: path,
            fallbackSeed: item.title,
            systemImage: "photo",
            contentMode: .fit
        )
        .accessibilityLabel(item.title)
    }

    #if os(iOS) || os(macOS)
        private func shareLink(_ artifact: EntityImageExportArtifact) -> some View {
            ShareLink(
                item: artifact.fileURL,
                preview: SharePreview(item.title)
            ) {
                Label("Share Original", systemImage: "square.and.arrow.up")
                    .labelStyle(.iconOnly)
            }
            .accessibilityHint("Shares a local copy without exposing your Prismedia session")
        }
    #endif

    private func load() async {
        isLoading = true
        errorMessage = nil
        projection = nil
        stillImage = nil
        animatedSequence = nil
        await clearExportArtifact()

        do {
            let loadedDetail: EntityDetail
            if let initialDetail, initialDetail.id == item.id {
                loadedDetail = initialDetail
            } else {
                loadedDetail = try await contentLoader.loadDetail(id: item.id)
            }
            guard !Task.isCancelled else { return }
            let loadedProjection = EntityImageMediaProjection(detail: loadedDetail)
            projection = loadedProjection

            if loadedProjection.mediaKind == .video {
                isLoading = false
                return
            }

            guard loadedProjection.sourcePath != nil else {
                isLoading = false
                return
            }
            let data = try await contentLoader.loadSourceData(id: item.id)
            guard !Task.isCancelled else { return }

            switch loadedProjection.mediaKind {
            case .animatedImage:
                animatedSequence = await Task.detached(priority: .userInitiated) {
                    AnimatedImageSequence.decode(data: data)
                }.value
                if animatedSequence == nil {
                    stillImage = await decodeStillImage(data)
                }
            case .stillImage:
                stillImage = await decodeStillImage(data)
            case .video:
                break
            }
            await createExportArtifact(
                data: data,
                projection: loadedProjection
            )
            isLoading = false
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            if projection?.fallbackArtworkPath != nil || item.bestCoverPath != nil {
                isLoading = false
            } else {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func decodeStillImage(_ data: Data) async -> Image? {
        let decoded = await Task.detached(priority: .userInitiated) {
            EntityImageStillDecoder.decode(data: data, maximumPixelSize: 8_192)
        }.value
        guard let decoded else { return nil }
        return Image(decorative: decoded, scale: 1, orientation: .up)
    }

    private func createExportArtifact(
        data: Data,
        projection: EntityImageMediaProjection
    ) async {
        #if !os(tvOS)
            guard
                let artifact = try? await exportStore.createArtifact(
                    data: data,
                    title: projection.title,
                    mimeType: projection.mimeType
                )
            else { return }
            guard !Task.isCancelled else {
                await exportStore.removeArtifact(artifact)
                return
            }
            exportArtifact = artifact
        #endif
    }

    private func clearExportArtifact() async {
        guard let exportArtifact else { return }
        self.exportArtifact = nil
        await exportStore.removeArtifact(exportArtifact)
    }

    private func removeExportArtifact() {
        guard let exportArtifact else { return }
        self.exportArtifact = nil
        Task { await exportStore.removeArtifact(exportArtifact) }
    }
}

#if DEBUG
    #Preview("Image Viewer Page") {
        let loader = EntityMediaPreviewLoader(
            details: EntityImageViewerPreviewData.details
        )
        let contentLoader = EntityMediaContentLoader(
            detailLoader: loader,
            sourceLoader: loader,
            retainedItems: EntityImageViewerPreviewData.items
        )
        EntityImageViewerPage(
            item: EntityImageViewerPreviewData.items[0],
            initialDetail: EntityImageViewerPreviewData.details[
                EntityImageViewerPreviewData.firstID
            ],
            contentLoader: contentLoader,
            exportStore: EntityImageExportStore(previewDisabled: true),
            isActive: true,
            showsControls: true
        )
        .background(.black)
    }
#endif
