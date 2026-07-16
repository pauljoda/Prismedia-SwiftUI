#if os(iOS) || os(macOS)
    import SwiftUI

    struct MusicArtistDetailView: View {
        @Environment(PrismediaAppEnvironment.self) private var environment
        @Environment(MusicPlayerController.self) private var controller
        @Environment(\.dynamicTypeSize) private var dynamicTypeSize
        @State private var artworkPalette: ArtworkPalette?
        @State private var loadingQueueMode: MusicQueueStartMode?
        @State private var playbackError: String?
        let detail: EntityDetail

        private var albums: [EntityThumbnail] {
            (detail.childrenByKind + detail.relationships)
                .filter { $0.kind == .audioLibrary }
                .flatMap(\.entities)
        }

        private var portraitPath: String? {
            detail.capabilities.compactMap { capability -> EntityImagesCapability? in
                guard case .images(let images) = capability else { return nil }
                return images
            }.first.flatMap { images in
                images.items.first { ["portrait", "profile", "cover", "thumbnail"].contains($0.kind) }?.path
                    ?? images.thumbnail2xURL
                    ?? images.thumbnailURL
                    ?? images.coverURL
            }
        }

        var body: some View {
            MusicBrowseBackdrop(
                artworkPath: portraitPath,
                previewPath: nil,
                fallbackSeed: detail.title,
                systemImage: "music.mic",
                palette: $artworkPalette
            ) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: PrismediaSpacing.extraLarge) {
                        artistHeader
                        playbackButtons
                        if !albums.isEmpty {
                            Text("Albums")
                                .font(.title3.bold())
                            albumGrid
                        }
                    }
                    .padding(PrismediaSpacing.large)
                    .padding(.bottom, PrismediaSpacing.section)
                }
            }
            .navigationTitle(detail.title)
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .alert("Couldn’t Start Playback", isPresented: playbackErrorPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(playbackError ?? "Please try again.")
            }
        }

        private var artistHeader: some View {
            VStack(spacing: PrismediaSpacing.small) {
                RemotePosterImage(
                    path: portraitPath,
                    fallbackSeed: detail.title,
                    systemImage: "music.mic"
                )
                .frame(width: 58, height: 58)
                .clipShape(Circle())
                Text(detail.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, PrismediaSpacing.small)
        }

        private var playbackButtons: some View {
            MusicPlaybackButtons(
                loadingMode: loadingQueueMode,
                isDisabled: albums.isEmpty
            ) { queueMode in
                Task { await playArtist(queueMode: queueMode) }
            }
        }

        private var albumGrid: some View {
            LazyVGrid(
                columns: albumColumns,
                spacing: PrismediaSpacing.large
            ) {
                ForEach(albums) { album in
                    NavigationLink(value: EntityLink(thumbnail: album, previewSubtitle: detail.title)) {
                        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                            Color.clear
                                .aspectRatio(1, contentMode: .fit)
                                .overlay {
                                    RemotePosterImage(
                                        path: album.bestCoverPath,
                                        fallbackSeed: album.title,
                                        systemImage: "square.stack"
                                    )
                                }
                                .clipShape(RoundedRectangle(cornerRadius: PrismediaRadius.compact, style: .continuous))
                            Text(album.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
                            Text(album.musicMetadataValue(matching: ["year", "date"]) ?? detail.title)
                                .font(.caption)
                                .foregroundStyle(artworkPalette?.secondary.color ?? PrismediaColor.textSecondary)
                                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .onAppear { prewarmArtwork(after: album.id) }
                }
            }
        }

        private var albumColumns: [GridItem] {
            if dynamicTypeSize.isAccessibilitySize {
                return [GridItem(.flexible())]
            }
            return [
                GridItem(.flexible(), spacing: PrismediaSpacing.small),
                GridItem(.flexible(), spacing: PrismediaSpacing.small),
            ]
        }

        private func prewarmArtwork(after itemID: UUID) {
            guard let client = environment.client else { return }
            let urls =
                EntityGridArtworkPrewarming
                .paths(after: itemID, in: albums)
                .compactMap { client.assetURL(for: $0) }
            guard !urls.isEmpty else { return }
            Task(priority: .utility) { await RemoteArtworkPipeline.shared.prewarm(urls) }
        }

        private func playArtist(queueMode: MusicQueueStartMode) async {
            guard let client = environment.client else { return }
            guard loadingQueueMode == nil else { return }
            loadingQueueMode = queueMode
            defer { loadingQueueMode = nil }
            do {
                let tracks = try await MusicLibraryQueueLoader(client: client).tracks(
                    in: albums,
                    artist: detail.title
                )
                guard !tracks.isEmpty else { return }
                controller.preparePlayback(
                    tracks: tracks,
                    queueMode: queueMode
                )
                await MusicQueueArtworkPreloader(
                    playbackService: client,
                    artworkLoader: environment.artworkLoader
                ).prewarm(queue: controller.queue)
                guard !Task.isCancelled else { return }
                controller.resume()
            } catch is CancellationError {
                return
            } catch {
                playbackError = error.localizedDescription
            }
        }

        private var playbackErrorPresented: Binding<Bool> {
            Binding(
                get: { playbackError != nil },
                set: { if !$0 { playbackError = nil } }
            )
        }

        #if DEBUG
            fileprivate static let previewDetail: EntityDetail = {
                let json = """
                    {"id":"cccccccc-cccc-cccc-cccc-cccccccccccc","kind":"music-artist","title":"AmaLee","hasSourceMedia":false,"capabilities":[],"relationships":[],
                    "childrenByKind":[{"kind":"audio-library","label":"Albums","entities":[
                    {"id":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1","kind":"audio-library","title":"Rise of the Monarch","meta":[{"icon":"year","label":"2025"}]},
                    {"id":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb2","kind":"audio-library","title":"Nostalgia","meta":[{"icon":"year","label":"2024"}]}]}]}
                    """
                return try! PrismediaJSON.decoder().decode(EntityDetail.self, from: Data(json.utf8))
            }()
        #endif
    }

    #if DEBUG
        #Preview("Music Artist Detail · Dark") {
            @Previewable @State var controller = MusicPreviewData.controller(playing: false)
            PreviewShell(signedIn: true) {
                NavigationStack { MusicArtistDetailView(detail: MusicArtistDetailView.previewDetail) }
                    .environment(controller)
            }
            .preferredColorScheme(.dark)
        }

        #Preview("Music Artist Detail · Accessibility") {
            @Previewable @State var controller = MusicPreviewData.controller(playing: false)
            PreviewShell(signedIn: true) {
                NavigationStack { MusicArtistDetailView(detail: MusicArtistDetailView.previewDetail) }
                    .environment(controller)
            }
            .environment(\.dynamicTypeSize, .accessibility3)
        }
    #endif
#endif
