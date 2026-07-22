#if os(iOS) || os(macOS)
    import SwiftUI

    struct MusicAlbumDetailView: View {
        @Environment(PrismediaAppEnvironment.self) private var environment
        @Environment(MusicPlayerController.self) private var controller
        @State private var artworkPalette: ArtworkPalette?
        @State private var resolvedParentArtist: String?
        @State private var trackForCollection: MusicTrack?
        @State private var selectedSection = EntityDetailSectionID.details
        let detail: EntityDetail
        let preview: EntityLinkPreview?
        let sectionSupport: EntityDetailSectionSupport

        init(
            detail: EntityDetail,
            preview: EntityLinkPreview? = nil,
            sectionSupport: EntityDetailSectionSupport = EntityDetailSectionSupport()
        ) {
            self.detail = detail
            self.preview = preview
            self.sectionSupport = sectionSupport
        }

        private var artist: String {
            MusicPresentation.albumArtist(detail: detail, resolvedParentArtist: resolvedParentArtist)
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
            MusicEntityProjection.tracks(in: detail, artist: artist)
        }

        private var trackSections: [MusicTrackSection] {
            MusicTrackSection.sections(for: tracks)
        }

        private var facts: MusicAlbumFacts {
            MusicPresentation.albumFacts(detail: detail, tracks: tracks)
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
                List {
                    albumHeader
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
                        MusicTrackSectionsView(
                            sections: trackSections,
                            onPlay: { track in
                                controller.play(tracks: tracks, startingAt: track.id)
                            },
                            onAddToCollection: { trackForCollection = $0 }
                        )
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
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
        }

        private var albumHeader: some View {
            VStack(spacing: PrismediaSpacing.medium) {
                EntityThumbnailArtworkFrame(aspectRatio: 1) {
                    RemotePosterImage(
                        path: artworkPath,
                        previewPath: preview?.artworkPath,
                        fallbackSeed: detail.title,
                        systemImage: "music.note"
                    )
                }
                .containerRelativeFrame(.horizontal, count: 5, span: 4, spacing: 0)
                .clipShape(RoundedRectangle(cornerRadius: PrismediaRadius.control, style: .continuous))
                .shadow(color: .black.opacity(0.4), radius: 24, y: 14)

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
                Text(facts.secondary)
                    .font(.caption)
                    .foregroundStyle(artworkPalette?.secondary.color ?? PrismediaColor.textSecondary)

                HStack(spacing: PrismediaSpacing.medium) {
                    PrismediaButton(
                        "Shuffle album",
                        systemImage: "shuffle",
                        form: .compactIcon,
                        action: shuffleAlbum
                    )

                    PrismediaButton(
                        "Play",
                        systemImage: "play.fill",
                        variant: .prominent,
                        action: playAlbum
                    )
                    .disabled(tracks.isEmpty)

                }
                .padding(.vertical, PrismediaSpacing.small)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, PrismediaSpacing.large)
            .padding(.bottom, PrismediaSpacing.large)
        }

        private func playAlbum() {
            controller.play(tracks: tracks, queueMode: .ordered)
        }

        private func shuffleAlbum() {
            controller.play(tracks: tracks, queueMode: .shuffled)
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
            fileprivate static let previewDetail: EntityDetail = {
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
    #endif
#endif
