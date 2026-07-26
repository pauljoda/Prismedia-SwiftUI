#if os(macOS)
import SwiftUI

struct MacMusicAlbumDetailView: View {
    @Environment(PrismediaAppEnvironment.self) private var environment
    @Environment(MusicPlayerController.self) private var controller
    @State private var artworkPalette: ArtworkPalette?
    @State private var resolvedParentArtist: String?
    @State private var selectedSection = EntityDetailSectionID.details

    let detail: EntityDetail
    let preview: EntityLinkPreview?
    let sectionSupport: EntityDetailSectionSupport

    private var artist: String {
        MusicPresentation.albumArtist(
            detail: detail,
            resolvedParentArtist: resolvedParentArtist
        )
    }

    private var artworkPath: String? {
        detail.capabilities.compactMap { capability -> EntityImagesCapability? in
            guard case .images(let images) = capability else { return nil }
            return images
        }.first.flatMap { images in
            images.items.first {
                ["cover", "poster", "thumbnail"].contains($0.kind)
            }?.path
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

    private var presentation: EntityDetailPresentation {
        EntityDetailPresentation(
            detail: detail,
            canEditMetadata: sectionSupport.canEditMetadata
        )
    }

    private var sections: [EntityDetailSection] {
        presentation.sections(mainTitle: "Tracks", mainSystemImage: "music.note.list")
    }

    var body: some View {
        MusicBrowseBackdrop(
            artworkPath: artworkPath,
            previewPath: preview?.artworkPath,
            fallbackSeed: detail.title,
            systemImage: "music.note",
            palette: $artworkPalette
        ) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                    albumHeader
                        .padding(.horizontal, PrismediaSpacing.extraExtraLarge)
                        .padding(.top, PrismediaSpacing.extraLarge)

                    EntityDetailSectionPicker(
                        sections: sections,
                        selection: $selectedSection,
                        horizontalPadding: PrismediaSpacing.extraExtraLarge
                    )

                    EntityDetailSectionSwitcher(
                        presentation: presentation,
                        selection: selectedSection,
                        horizontalPadding: PrismediaSpacing.extraExtraLarge,
                        support: sectionSupport
                    ) {
                        MusicTrackSectionsView(
                            sections: trackSections,
                            onPlay: { track in
                                controller.play(tracks: tracks, startingAt: track.id)
                            },
                            onAddToCollection: nil
                        )
                        .padding(.horizontal, PrismediaSpacing.extraExtraLarge)
                    }
                }
                .padding(.bottom, PrismediaSpacing.extraExtraLarge)
            }
        }
        .navigationTitle(detail.title)
        .task(id: detail.parentEntityID) { await resolveParentArtist() }
    }

    private var albumHeader: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .bottom, spacing: PrismediaSpacing.extraExtraLarge) {
                artwork(width: 240)
                albumInformation(alignment: .leading)
                    .frame(maxWidth: 560, alignment: .leading)
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                artwork(width: 200)
                    .frame(maxWidth: .infinity)
                albumInformation(alignment: .center)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func artwork(width: CGFloat) -> some View {
        EntityThumbnailArtworkFrame(aspectRatio: 1) {
            RemotePosterImage(
                path: artworkPath,
                previewPath: preview?.artworkPath,
                fallbackSeed: detail.title,
                systemImage: "music.note"
            )
        }
        .frame(width: width, height: width)
        .clipShape(.rect(cornerRadius: PrismediaRadius.control))
        .shadow(color: .black.opacity(0.38), radius: 22, y: 12)
    }

    private func albumInformation(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: PrismediaSpacing.small) {
            Text("ALBUM")
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

            Text(facts.secondary)
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

    private func playAlbum() {
        controller.play(tracks: tracks, queueMode: .ordered)
    }

    private func shuffleAlbum() {
        controller.play(tracks: tracks, queueMode: .shuffled)
    }

    private func resolveParentArtist() async {
        guard let parentID = detail.parentEntityID,
              let client = environment.client,
              let parents = try? await client.fetchEntityThumbnails(ids: [parentID]),
              let parent = parents.first,
              parent.kind == .musicArtist
        else { return }

        resolvedParentArtist = parent.title
    }
}

#if DEBUG
    #Preview("Mac Music Album Detail", traits: .fixedLayout(width: 1_080, height: 760)) {
        @Previewable @State var controller = MusicPreviewData.controller(playing: false)
        PreviewShell(signedIn: true) {
            NavigationStack {
                MacMusicAlbumDetailView(
                    detail: MusicAlbumDetailView.previewDetail,
                    preview: nil,
                    sectionSupport: EntityDetailSectionSupport()
                )
            }
            .environment(controller)
        }
        .preferredColorScheme(.dark)
    }
#endif
#endif
