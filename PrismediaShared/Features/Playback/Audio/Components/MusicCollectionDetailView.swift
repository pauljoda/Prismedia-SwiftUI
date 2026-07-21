#if os(iOS) || os(macOS)
    import SwiftUI

    struct MusicCollectionDetailView: View {
        @Environment(MusicPlayerController.self) private var controller
        @State private var phase: MusicCollectionPlaybackPhase = .loading
        @State private var artworkPalette: ArtworkPalette?
        @State private var loadingQueueMode: MusicQueueStartMode?

        let detail: EntityDetail
        let preview: EntityLinkPreview?
        let loader: MusicCollectionQueueLoader

        var body: some View {
            MusicBrowseBackdrop(
                artworkPath: artworkPath,
                previewPath: preview?.artworkPath,
                fallbackSeed: detail.title,
                systemImage: "rectangle.stack.badge.play",
                palette: $artworkPalette
            ) {
                List {
                    collectionHeader
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)

                    phaseContent
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(detail.title)
            .prismediaInlineNavigationTitle()
            .task(id: detail.id) { await load() }
        }

        private var collectionHeader: some View {
            VStack(spacing: PrismediaSpacing.medium) {
                EntityThumbnailArtworkFrame(aspectRatio: 1) {
                    RemotePosterImage(
                        path: artworkPath,
                        previewPath: preview?.artworkPath,
                        fallbackSeed: detail.title,
                        systemImage: "rectangle.stack.badge.play"
                    )
                }
                .containerRelativeFrame(.horizontal, count: 5, span: 4, spacing: 0)
                .clipShape(RoundedRectangle(cornerRadius: PrismediaRadius.control, style: .continuous))
                .shadow(color: .black.opacity(0.4), radius: 24, y: 14)

                Text(detail.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(collectionSummary)
                    .font(.subheadline)
                    .foregroundStyle(artworkPalette?.secondary.color ?? PrismediaColor.textSecondary)

                MusicPlaybackButtons(
                    loadingMode: loadingQueueMode,
                    isDisabled: currentSnapshot?.tracks.isEmpty != false
                ) { queueMode in
                    Task { await playAll(queueMode: queueMode) }
                }
                .padding(.vertical, PrismediaSpacing.small)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, PrismediaSpacing.large)
            .padding(.bottom, PrismediaSpacing.large)
        }

        @ViewBuilder
        private var phaseContent: some View {
            switch phase {
            case .loading:
                ProgressView("Loading collection audio…")
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .listRowBackground(Color.clear)
            case .content(let snapshot):
                MusicTrackSectionsView(
                    sections: snapshot.sections,
                    onPlay: { play($0, in: snapshot) },
                    onAddToCollection: nil
                )
            case .empty:
                ContentUnavailableView(
                    "No Playable Audio",
                    systemImage: "music.note",
                    description: Text("This collection no longer contains playable audio.")
                )
                .listRowBackground(Color.clear)
            case .failure(let message):
                ContentUnavailableView {
                    Label("Couldn’t Load Collection", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again") { Task { await load() } }
                }
                .listRowBackground(Color.clear)
            }
        }

        private var currentSnapshot: MusicCollectionPlaybackSnapshot? {
            guard case .content(let snapshot) = phase else { return nil }
            return snapshot
        }

        private var collectionSummary: String {
            guard let snapshot = currentSnapshot else { return "Audio Collection" }
            let count = snapshot.tracks.count
            return "\(count) \(count == 1 ? "song" : "songs")"
        }

        private var artworkPath: String? {
            detail.capabilities.compactMap { capability -> EntityImagesCapability? in
                guard case .images(let images) = capability else { return nil }
                return images
            }.first.flatMap { images in
                images.items.first { ["cover", "poster", "thumbnail"].contains($0.kind) }?.path
                    ?? images.coverURL
                    ?? images.thumbnail2xURL
                    ?? images.thumbnailURL
            }
        }

        private func load() async {
            phase = .loading
            do {
                let snapshot = try await loader.load(collectionID: detail.id)
                guard !Task.isCancelled else { return }
                phase = snapshot.tracks.isEmpty ? .empty : .content(snapshot)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                phase = .failure(error.localizedDescription)
            }
        }

        private func playAll(queueMode: MusicQueueStartMode) async {
            guard let snapshot = currentSnapshot else { return }
            guard loadingQueueMode == nil else { return }
            loadingQueueMode = queueMode
            defer { loadingQueueMode = nil }
            controller.play(
                tracks: snapshot.tracks,
                queueMode: queueMode
            )
        }

        private func play(
            _ track: MusicTrack,
            in snapshot: MusicCollectionPlaybackSnapshot
        ) {
            controller.play(tracks: snapshot.tracks, startingAt: track.id)
        }
    }

    #if DEBUG
        #Preview("Music Collection Detail") {
            @Previewable @State var controller = MusicPreviewData.controller(playing: false)
            let preview = MusicCollectionPreviewLoader()
            PreviewShell(signedIn: true) {
                NavigationStack {
                    MusicCollectionDetailView(
                        detail: EntityDetail(
                            id: MusicCollectionPreviewLoader.collection.id,
                            kind: .collection,
                            title: MusicCollectionPreviewLoader.collection.title,
                            parentEntityID: nil,
                            sortOrder: nil,
                            hasSourceMedia: false,
                            capabilities: [],
                            childrenByKind: [],
                            relationships: []
                        ),
                        preview: nil,
                        loader: MusicCollectionQueueLoader(
                            collectionItemsLoader: preview,
                            detailLoader: preview
                        )
                    )
                }
                .environment(controller)
            }
        }
    #endif
#endif
