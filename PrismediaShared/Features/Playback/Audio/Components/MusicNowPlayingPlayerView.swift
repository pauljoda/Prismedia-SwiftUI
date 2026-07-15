#if os(iOS)
    import SwiftUI

    struct MusicNowPlayingPlayerView: View {
        let track: MusicTrack
        let artworkNamespace: Namespace.ID
        let isActive: Bool
        let onShowQueue: () -> Void
        let onAddToCollection: () -> Void

        var body: some View {
            VStack(spacing: PrismediaSpacing.extraExtraLarge) {
                Button(action: onShowQueue) {
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .containerRelativeFrame(.horizontal) { width, _ in
                            max(min(width - (PrismediaSpacing.section * 2), 520), 1)
                        }
                        .overlay {
                            if isActive {
                                MusicNowPlayingArtwork(track: track)
                                    .matchedGeometryEffect(
                                        id: "music.now-playing.artwork.\(track.id.uuidString)",
                                        in: artworkNamespace,
                                        properties: .frame,
                                        anchor: .center
                                    )
                                    .zIndex(1)
                                    .shadow(color: .black.opacity(0.4), radius: 24, y: 16)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!isActive)
                .accessibilityHidden(!isActive)
                .accessibilityLabel("Show Queue")
                .accessibilityHint("Shows the playing queue")
                .simultaneousGesture(queueRevealGesture)
                .frame(maxHeight: .infinity, alignment: .top)
                .layoutPriority(1)

                metadata
                    .opacity(isActive ? 1 : 0)
                    .padding(.bottom, PrismediaSpacing.small)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        private var metadata: some View {
            HStack(spacing: PrismediaSpacing.medium) {
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                    Text(track.title)
                        .font(.title3.bold())
                        .lineLimit(1)
                    Text([track.album, track.artist].compactMap { $0 }.joined(separator: " — "))
                        .font(.body)
                        .foregroundStyle(PrismediaColor.onMedia.opacity(0.68))
                        .lineLimit(1)
                }
                Spacer()
                Button("Add to Collection", systemImage: "ellipsis", action: onAddToCollection)
                    .labelStyle(.iconOnly)
            }
            .font(.body.weight(.semibold))
            .padding(.horizontal, PrismediaSpacing.section)
        }

        private var queueRevealGesture: some Gesture {
            DragGesture(minimumDistance: 28)
                .onEnded { value in
                    let projectedDistance = min(value.translation.height, value.predictedEndTranslation.height)
                    guard projectedDistance < -72 else { return }
                    onShowQueue()
                }
        }
    }

    #if DEBUG
        #Preview("Now Playing Player") {
            @Previewable @Namespace var artworkNamespace
            MusicNowPlayingPlayerView(
                track: MusicPreviewData.tracks[0],
                artworkNamespace: artworkNamespace,
                isActive: true,
                onShowQueue: {},
                onAddToCollection: {}
            )
            .environment(PrismediaPreviewData.model(signedIn: true))
            .background(PrismediaBackdrop())
        }
    #endif
#endif
