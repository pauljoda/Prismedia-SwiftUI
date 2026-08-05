#if os(iOS) || os(macOS)
    import SwiftUI

    struct MusicNowPlayingPlayerView: View {
        let track: MusicTrack
        let artworkNamespace: Namespace.ID
        let artworkIsSource: Bool
        let artworkAspectRatio: Double
        let artworkFallbackSeed: String
        let artworkSystemImage: String
        let isActive: Bool
        let onShowQueue: () -> Void
        let onNavigate: (EntityLink) -> Void
        let onAddToCollection: (() -> Void)?

        init(
            track: MusicTrack,
            artworkNamespace: Namespace.ID,
            artworkIsSource: Bool = true,
            artworkAspectRatio: Double = 1,
            artworkFallbackSeed: String? = nil,
            artworkSystemImage: String = "music.note",
            isActive: Bool,
            onShowQueue: @escaping () -> Void,
            onNavigate: @escaping (EntityLink) -> Void,
            onAddToCollection: (() -> Void)?
        ) {
            self.track = track
            self.artworkNamespace = artworkNamespace
            self.artworkIsSource = artworkIsSource
            self.artworkAspectRatio = artworkAspectRatio
            self.artworkFallbackSeed = artworkFallbackSeed ?? track.album ?? track.title
            self.artworkSystemImage = artworkSystemImage
            self.isActive = isActive
            self.onShowQueue = onShowQueue
            self.onNavigate = onNavigate
            self.onAddToCollection = onAddToCollection
        }

        var body: some View {
            VStack(spacing: PrismediaSpacing.extraExtraLarge) {
                Button(action: onShowQueue) {
                    GeometryReader { geometry in
                        let artworkSize = fittedArtworkSize(in: geometry.size)

                        Color.clear
                            .frame(width: artworkSize.width, height: artworkSize.height)
                            .overlay {
                                if isActive {
                                    MusicNowPlayingArtwork(
                                        track: track,
                                        aspectRatio: artworkAspectRatio,
                                        fallbackSeed: artworkFallbackSeed,
                                        systemImage: artworkSystemImage
                                    )
                                    .matchedGeometryEffect(
                                        id: "music.now-playing.artwork.\(track.id.uuidString)",
                                        in: artworkNamespace,
                                        properties: .frame,
                                        anchor: .center,
                                        isSource: artworkIsSource
                                    )
                                    .zIndex(1)
                                    .shadow(color: .black.opacity(0.4), radius: 24, y: 16)
                                }
                            }
                            .contentShape(Rectangle())
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)
                .buttonStyle(.plain)
                .disabled(!isActive)
                .accessibilityHidden(!isActive)
                .accessibilityLabel("Show Queue")
                .accessibilityHint("Shows the playing queue")
                .simultaneousGesture(queueRevealGesture)

                metadata
                    .opacity(isActive ? 1 : 0)
                    .padding(.bottom, PrismediaSpacing.small)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
                MusicTrackActionsMenu(
                    track: track,
                    onNavigate: onNavigate,
                    onAddToCollection: onAddToCollection
                )
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

        private func fittedArtworkSize(in availableSize: CGSize) -> CGSize {
            let horizontalInset = PrismediaSpacing.section * 2
            let availableWidth = max(1, availableSize.width - horizontalInset)
            let maximumWidth = artworkAspectRatio < 1 ? min(availableWidth * 0.7, 300) : 520
            let width = max(1, min(availableWidth, maximumWidth, availableSize.height * artworkAspectRatio))
            return CGSize(width: width, height: width / artworkAspectRatio)
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
                onNavigate: { _ in },
                onAddToCollection: {}
            )
            .environment(PrismediaPreviewData.model(signedIn: true))
            .background(PrismediaBackdrop())
        }
    #endif
#endif
