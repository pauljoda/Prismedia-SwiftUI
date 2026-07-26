#if os(iOS) || os(macOS)
    import SwiftUI

    struct MusicAlbumLoadingView: View {
        @State private var artworkPalette: ArtworkPalette?
        let preview: EntityLinkPreview

        var body: some View {
            MusicBrowseBackdrop(
                artworkPath: nil,
                previewPath: preview.artworkPath,
                fallbackSeed: preview.title,
                systemImage: "music.note",
                palette: $artworkPalette
            ) {
                #if os(macOS)
                    macLoadingContent
                #else
                    compactLoadingContent
                #endif
            }
            .accessibilityRepresentation {
                ProgressView {
                    Text("Loading \(preview.title)…")
                }
            }
        }

        private var albumArtwork: some View {
            EntityThumbnailArtworkFrame(aspectRatio: 1) {
                RemotePosterImage(
                    path: preview.artworkPath,
                    fallbackSeed: preview.title,
                    systemImage: "music.note"
                )
            }
            .clipShape(.rect(cornerRadius: PrismediaRadius.control))
            .shadow(color: .black.opacity(0.4), radius: 24, y: 14)
        }

        private var compactLoadingContent: some View {
            VStack(spacing: PrismediaSpacing.medium) {
                Spacer(minLength: 0)

                albumArtwork
                    .containerRelativeFrame(.horizontal, count: 5, span: 4, spacing: 0)

                loadingInformation(alignment: .center)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, PrismediaSpacing.large)
        }

        #if os(macOS)
            private var macLoadingContent: some View {
                ScrollView {
                    HStack(alignment: .bottom, spacing: PrismediaSpacing.extraExtraLarge) {
                        albumArtwork
                            .frame(width: 240, height: 240)

                        loadingInformation(alignment: .leading)
                            .frame(maxWidth: 560, alignment: .leading)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, PrismediaSpacing.extraExtraLarge)
                    .padding(.top, PrismediaSpacing.extraLarge)
                    .padding(.bottom, PrismediaSpacing.extraExtraLarge)
                }
            }
        #endif

        private func loadingInformation(alignment: HorizontalAlignment) -> some View {
            VStack(alignment: alignment, spacing: PrismediaSpacing.medium) {
                Text("ALBUM")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PrismediaColor.textMuted)

                Text(preview.title)
                    .font(alignment == .center ? .title2.bold() : .largeTitle.bold())
                    .multilineTextAlignment(alignment == .center ? .center : .leading)

                if let subtitle = preview.subtitle {
                    Text(subtitle)
                        .font(alignment == .center ? .headline : .title3.weight(.semibold))
                        .foregroundStyle(artworkPalette?.primary.color ?? PrismediaColor.accent)
                }

                PrismediaLoadingMark()
            }
        }
    }

    #if DEBUG
        #Preview("Music Album Loading") {
            PreviewShell(signedIn: true) {
                MusicAlbumLoadingView(
                    preview: EntityLinkPreview(
                        title: "Emerald Sessions",
                        subtitle: "The Night Owls",
                        artworkPath: nil
                    )
                )
            }
        }
    #endif
#endif
