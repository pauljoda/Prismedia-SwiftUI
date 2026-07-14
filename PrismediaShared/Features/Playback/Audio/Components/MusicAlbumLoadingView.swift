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
                VStack(spacing: PrismediaSpacing.medium) {
                    Spacer(minLength: 0)

                    EntityThumbnailArtworkFrame(aspectRatio: 1) {
                        RemotePosterImage(
                            path: preview.artworkPath,
                            fallbackSeed: preview.title,
                            systemImage: "music.note"
                        )
                    }
                    .containerRelativeFrame(.horizontal, count: 5, span: 4, spacing: 0)
                    .clipShape(RoundedRectangle(cornerRadius: PrismediaRadius.control, style: .continuous))
                    .shadow(color: .black.opacity(0.4), radius: 24, y: 14)

                    Text(preview.title)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    if let subtitle = preview.subtitle {
                        Text(subtitle)
                            .font(.headline)
                            .foregroundStyle(artworkPalette?.primary.color ?? PrismediaColor.accent)
                    }

                    PrismediaLoadingMark()

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, PrismediaSpacing.large)
            }
            .accessibilityRepresentation {
                ProgressView {
                    Text("Loading \(preview.title)…")
                }
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
