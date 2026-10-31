#if os(iOS)
    import SwiftUI

    /// The regular-width mini player collapsed to the playing artwork, floating in
    /// a bottom corner out of the way of the content. Tap it to bring the bar back;
    /// drag or fling it to move it to the other corner.
    struct IPadMusicMiniPlayerBubble: View {
        /// Pairs this artwork with the bar's, so collapsing and expanding move one
        /// piece of artwork between the bar and the corner.
        static let artworkTransitionID = "music.mini-player.artwork"

        @Environment(MusicPlayerController.self) private var controller
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Binding var edge: HorizontalEdge
        @State private var dragOffset: CGFloat = 0
        @State private var isDragging = false

        let artworkNamespace: Namespace.ID
        let artworkPalette: ArtworkPalette?
        let onExpand: () -> Void

        init(
            edge: Binding<HorizontalEdge>,
            artworkNamespace: Namespace.ID,
            artworkPalette: ArtworkPalette?,
            onExpand: @escaping () -> Void
        ) {
            _edge = edge
            self.artworkNamespace = artworkNamespace
            self.artworkPalette = artworkPalette
            self.onExpand = onExpand
        }

        var body: some View {
            if let track = controller.currentTrack {
                Button(action: onExpand) {
                    MusicNowPlayingArtwork(track: track, cornerRadius: PrismediaRadius.control)
                        .frame(width: 56, height: 56)
                        .matchedGeometryEffect(id: Self.artworkTransitionID, in: artworkNamespace)
                        .overlay(alignment: .topTrailing) {
                            playingBadge
                        }
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .shadow(color: .black.opacity(isDragging ? 0.6 : 0.45), radius: isDragging ? 24 : 14, y: 10)
                .scaleEffect(isDragging ? 1.08 : 1)
                .offset(x: dragOffset)
                .highPriorityGesture(moveGesture)
                .padding(PrismediaSpacing.extraExtraLarge)
                .accessibilityLabel("Show Player, \(controller.entryTitle ?? track.title)")
                .accessibilityHint("Drag to move it to the other side")
                .accessibilityAction(named: "Move to Other Side") {
                    moveTo(edge == .leading ? .trailing : .leading)
                }
                .accessibilityIdentifier("music.mini-player.collapsed")
            }
        }

        private var playingBadge: some View {
            Image(systemName: "waveform")
                .font(.caption2.weight(.bold))
                .foregroundStyle(artworkPalette?.primary.color ?? PrismediaColor.textPrimary)
                .symbolEffect(
                    .variableColor.iterative,
                    options: .repeating,
                    isActive: controller.isPlaying && !reduceMotion
                )
                .padding(PrismediaSpacing.extraSmall)
                .background(.ultraThinMaterial, in: .circle)
                .offset(x: PrismediaSpacing.small, y: -PrismediaSpacing.small)
                .opacity(controller.isPlaying ? 1 : 0)
                .accessibilityHidden(true)
        }

        /// A throw toward the other side moves it there; a short nudge settles back.
        private var moveGesture: some Gesture {
            DragGesture(minimumDistance: 8)
                .onChanged { value in
                    isDragging = true
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    let throwDistance = value.predictedEndTranslation.width
                    if edge == .trailing, throwDistance < -120 {
                        moveTo(.leading)
                    } else if edge == .leading, throwDistance > 120 {
                        moveTo(.trailing)
                    } else {
                        moveTo(edge)
                    }
                }
        }

        private func moveTo(_ newEdge: HorizontalEdge) {
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.38, extraBounce: 0.06)) {
                edge = newEdge
                dragOffset = 0
                isDragging = false
            }
        }
    }

    #if DEBUG
        #Preview("Collapsed Mini Player") {
            @Previewable @State var controller = MusicPreviewData.controller()
            @Previewable @State var edge = HorizontalEdge.trailing
            @Previewable @Namespace var artworkNamespace

            PreviewShell(signedIn: true) {
                Color.clear
                    .overlay(alignment: edge == .leading ? .bottomLeading : .bottomTrailing) {
                        IPadMusicMiniPlayerBubble(
                            edge: $edge,
                            artworkNamespace: artworkNamespace,
                            artworkPalette: nil,
                            onExpand: {}
                        )
                        .environment(controller)
                    }
            }
        }
    #endif
#endif
