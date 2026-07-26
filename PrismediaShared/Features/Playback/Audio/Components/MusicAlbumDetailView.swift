#if os(iOS) || os(macOS)
    import SwiftUI

    struct MusicAlbumDetailView: View {
        @Environment(PrismediaAppEnvironment.self) private var environment
        @Environment(MusicPlayerController.self) private var controller
        @State private var artworkPalette: ArtworkPalette?
        @State private var collectionPhase = MusicCollectionPlaybackPhase.loading
        @State private var resolvedParentArtist: String?
        @State private var trackForCollection: MusicTrack?
        @State private var selectedSection = EntityDetailSectionID.details
        let detail: EntityDetail
        let preview: EntityLinkPreview?
        let collectionLoader: MusicCollectionQueueLoader?
        let sectionSupport: EntityDetailSectionSupport

        init(
            detail: EntityDetail,
            preview: EntityLinkPreview? = nil,
            collectionLoader: MusicCollectionQueueLoader? = nil,
            sectionSupport: EntityDetailSectionSupport = EntityDetailSectionSupport()
        ) {
            self.detail = detail
            self.preview = preview
            self.collectionLoader = collectionLoader
            self.sectionSupport = sectionSupport
        }

        private var artist: String {
            guard collectionLoader == nil else { return collectionArtist }
            return MusicPresentation.albumArtist(
                detail: detail,
                resolvedParentArtist: resolvedParentArtist
            )
        }

        private var collectionArtist: String {
            let artists = Set(
                tracks.compactMap { track -> String? in
                    let artist = track.artist?.trimmingCharacters(in: .whitespacesAndNewlines)
                    return artist?.isEmpty == false ? artist : nil
                }
            )
            if artists.count == 1, let artist = artists.first { return artist }
            return artists.isEmpty ? "Audio Collection" : "Various Artists"
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

        private var tracks: [MusicTrack] {
            if collectionLoader != nil {
                guard case .content(let snapshot) = collectionPhase else { return [] }
                return snapshot.tracks
            }
            return MusicEntityProjection.tracks(in: detail, artist: artist)
        }

        private var trackSections: [MusicTrackSection] {
            if collectionLoader != nil, case .content(let snapshot) = collectionPhase {
                return snapshot.sections
            }
            return MusicTrackSection.sections(for: tracks)
        }

        private var facts: MusicAlbumFacts {
            MusicPresentation.albumFacts(detail: detail, tracks: tracks)
        }

        private var secondaryFacts: String {
            guard collectionLoader != nil else { return facts.secondary }
            switch collectionPhase {
            case .loading:
                return "Loading tracks…"
            case .content:
                return facts.secondary
            case .empty:
                return "No playable audio"
            case .failure:
                return "Tracks unavailable"
            }
        }

        private var sectionPresentation: EntityDetailPresentation {
            EntityDetailPresentation(
                detail: detail,
                canEditMetadata: sectionSupport.canEditMetadata
            )
        }

        private var sections: [EntityDetailSection] {
            sectionPresentation.sections(
                mainTitle: "Tracks",
                mainSystemImage: "music.note.list"
            )
        }

        var body: some View {
            MusicBrowseBackdrop(
                artworkPath: artworkPath,
                previewPath: preview?.artworkPath,
                fallbackSeed: detail.title,
                systemImage: "music.note",
                palette: $artworkPalette
            ) {
                #if os(macOS)
                    wideContent
                #else
                    ViewThatFits(in: .horizontal) {
                        wideContent
                            .frame(minWidth: 680)
                        compactContent
                    }
                #endif
            }
            .navigationTitle(detail.title)
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .sheet(item: $trackForCollection) { track in
                    AddToCollectionSheet(
                        items: [CollectionEntityReference(entityType: .audioTrack, entityID: track.id)]
                    )
                    .environment(environment)
                }
            #endif
            .task(id: detail.parentEntityID) { await resolveParentArtist() }
            .task(id: detail.id) { await loadCollectionIfNeeded() }
        }

        private var compactContent: some View {
            List {
                compactAlbumHeader
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                EntityDetailSectionPicker(
                    sections: sections,
                    selection: $selectedSection,
                    horizontalPadding: PrismediaSpacing.large
                )

                EntityDetailSectionSwitcher(
                    presentation: sectionPresentation,
                    selection: selectedSection,
                    horizontalPadding: PrismediaSpacing.large,
                    support: sectionSupport
                ) {
                    trackContent
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }

        private var wideContent: some View {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                    wideAlbumHeader
                        .padding(.horizontal, PrismediaSpacing.extraExtraLarge)
                        .padding(.top, PrismediaSpacing.extraLarge)

                    EntityDetailSectionPicker(
                        sections: sections,
                        selection: $selectedSection,
                        horizontalPadding: PrismediaSpacing.extraExtraLarge
                    )

                    EntityDetailSectionSwitcher(
                        presentation: sectionPresentation,
                        selection: selectedSection,
                        horizontalPadding: PrismediaSpacing.extraExtraLarge,
                        support: sectionSupport
                    ) {
                        trackContent
                            .padding(.horizontal, PrismediaSpacing.extraExtraLarge)
                    }
                }
                .padding(.bottom, PrismediaSpacing.extraExtraLarge)
            }
        }

        private var trackList: some View {
            MusicTrackSectionsView(
                sections: trackSections,
                onPlay: { track in
                    controller.play(tracks: tracks, startingAt: track.id)
                },
                onAddToCollection: addTrackToCollection
            )
        }

        @ViewBuilder
        private var trackContent: some View {
            if collectionLoader == nil {
                trackList
            } else {
                switch collectionPhase {
                case .loading:
                    ProgressView("Loading collection audio…")
                        .frame(maxWidth: .infinity, minHeight: 180)
                        .listRowBackground(Color.clear)
                case .content:
                    trackList
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
                        Button("Try Again") { Task { await loadCollectionIfNeeded() } }
                    }
                    .listRowBackground(Color.clear)
                }
            }
        }

        private var compactAlbumHeader: some View {
            VStack(spacing: PrismediaSpacing.medium) {
                albumArtwork
                    .containerRelativeFrame(.horizontal, count: 5, span: 4, spacing: 0)

                Text(detail.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text(artist)
                    .font(.headline)
                    .foregroundStyle(artworkPalette?.primary.color ?? PrismediaColor.accent)
                if !facts.primary.isEmpty {
                    Text(facts.primary)
                        .font(.subheadline)
                        .foregroundStyle(artworkPalette?.secondary.color ?? PrismediaColor.textSecondary)
                }
                Text(secondaryFacts)
                    .font(.caption)
                    .foregroundStyle(artworkPalette?.secondary.color ?? PrismediaColor.textSecondary)

                HStack(spacing: PrismediaSpacing.medium) {
                    PrismediaButton(
                        "Shuffle album",
                        systemImage: "shuffle",
                        form: .compactIcon,
                        action: shuffleAlbum
                    )
                    .disabled(tracks.isEmpty)
                    .accessibilityIdentifier("music.album.shuffle")

                    PrismediaButton(
                        "Play",
                        systemImage: "play.fill",
                        variant: .prominent,
                        action: playAlbum
                    )
                    .disabled(tracks.isEmpty)
                    .accessibilityIdentifier("music.album.play")

                }
                .padding(.vertical, PrismediaSpacing.small)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, PrismediaSpacing.large)
            .padding(.bottom, PrismediaSpacing.large)
        }

        private var wideAlbumHeader: some View {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .bottom, spacing: PrismediaSpacing.extraExtraLarge) {
                    albumArtwork
                        .frame(width: 240, height: 240)
                    wideAlbumInformation(alignment: .leading)
                        .frame(maxWidth: 560, alignment: .leading)
                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                    albumArtwork
                        .frame(width: 200, height: 200)
                        .frame(maxWidth: .infinity)
                    wideAlbumInformation(alignment: .center)
                        .frame(maxWidth: .infinity)
                }
            }
        }

        private var albumArtwork: some View {
            EntityThumbnailArtworkFrame(aspectRatio: 1) {
                RemotePosterImage(
                    path: artworkPath,
                    previewPath: preview?.artworkPath,
                    fallbackSeed: detail.title,
                    systemImage: "music.note"
                )
            }
            .clipShape(.rect(cornerRadius: PrismediaRadius.control))
            .shadow(color: .black.opacity(0.38), radius: 22, y: 12)
        }

        private func wideAlbumInformation(alignment: HorizontalAlignment) -> some View {
            VStack(alignment: alignment, spacing: PrismediaSpacing.small) {
                Text(collectionLoader == nil ? "ALBUM" : "COLLECTION")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PrismediaColor.textMuted)

                Text(detail.title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(alignment == .center ? .center : .leading)
                    .lineLimit(3)

                Text(artist)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(artworkPalette?.primary.color ?? PrismediaColor.accent)

                if !facts.primary.isEmpty {
                    Text(facts.primary)
                        .font(.subheadline)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }

                Text(secondaryFacts)
                    .font(.caption)
                    .foregroundStyle(PrismediaColor.textMuted)

                HStack(spacing: PrismediaSpacing.medium) {
                    PrismediaButton(
                        "Play",
                        systemImage: "play.fill",
                        variant: .prominent,
                        action: playAlbum
                    )
                    .disabled(tracks.isEmpty)
                    .accessibilityIdentifier("music.album.play")

                    PrismediaButton(
                        "Shuffle",
                        systemImage: "shuffle",
                        action: shuffleAlbum
                    )
                    .disabled(tracks.isEmpty)
                    .accessibilityIdentifier("music.album.shuffle")
                }
                .padding(.top, PrismediaSpacing.small)
            }
        }

        private var addTrackToCollection: ((MusicTrack) -> Void)? {
            #if os(iOS)
                { trackForCollection = $0 }
            #else
                nil
            #endif
        }

        private func playAlbum() {
            controller.play(tracks: tracks, queueMode: .ordered)
        }

        private func shuffleAlbum() {
            controller.play(tracks: tracks, queueMode: .shuffled)
        }

        private func loadCollectionIfNeeded() async {
            guard let collectionLoader else { return }
            collectionPhase = .loading
            do {
                let snapshot = try await collectionLoader.load(collectionID: detail.id)
                guard !Task.isCancelled else { return }
                collectionPhase = snapshot.tracks.isEmpty ? .empty : .content(snapshot)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                collectionPhase = .failure(error.localizedDescription)
            }
        }

        private func resolveParentArtist() async {
            guard let parentID = detail.parentEntityID, let client = environment.client else { return }
            guard let parents = try? await client.fetchEntityThumbnails(ids: [parentID]),
                let parent = parents.first
            else { return }
            guard parent.kind == .musicArtist else { return }
            resolvedParentArtist = parent.title
        }

        #if DEBUG
            static let previewDetail: EntityDetail = {
                let json = """
                    {"id":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","kind":"audio-library","title":"1","hasSourceMedia":true,
                    "capabilities":[],"relationships":[{"kind":"music-artist","label":"Artist","entities":[{"id":"cccccccc-cccc-cccc-cccc-cccccccccccc","kind":"music-artist","title":"The Beatles"}]}],
                    "childrenByKind":[{"kind":"audio-track","label":"Tracks","entities":[
                    {"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1","kind":"audio-track","title":"Let It Be","sortOrder":1,"meta":[{"icon":"duration","label":"4:03"}]},
                    {"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2","kind":"audio-track","title":"Come Together","sortOrder":2,"meta":[{"icon":"duration","label":"4:19"}]}]}]}
                    """
                return try! PrismediaJSON.decoder().decode(EntityDetail.self, from: Data(json.utf8))
            }()
        #endif
    }

    #if DEBUG
        #Preview("Music Album Detail · Dark") {
            @Previewable @State var controller = MusicPreviewData.controller(playing: false)
            PreviewShell(signedIn: true) {
                NavigationStack { MusicAlbumDetailView(detail: MusicAlbumDetailView.previewDetail) }
                    .environment(controller)
            }
            .preferredColorScheme(.dark)
        }

        #Preview("Music Album Detail · Accessibility") {
            @Previewable @State var controller = MusicPreviewData.controller(playing: false)
            PreviewShell(signedIn: true) {
                NavigationStack { MusicAlbumDetailView(detail: MusicAlbumDetailView.previewDetail) }
                    .environment(controller)
            }
            .environment(\.dynamicTypeSize, .accessibility3)
        }

        #Preview("Music Album Detail · Audio Collection") {
            @Previewable @State var controller = MusicPreviewData.controller(playing: false)
            let preview = MusicCollectionPreviewLoader()

            PreviewShell(signedIn: true) {
                NavigationStack {
                    MusicAlbumDetailView(
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
                        collectionLoader: MusicCollectionQueueLoader(
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
