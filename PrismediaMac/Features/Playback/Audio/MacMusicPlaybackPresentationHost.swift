#if os(macOS)
    import SwiftUI

    struct MacMusicPlaybackPresentationHost<Content: View>: View {
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(\.musicMiniPlayerVisibility) private var miniPlayerVisibility
        @Environment(\.macMusicPlaybackPresentation) private var presentation
        @State private var artworkPalette: ArtworkPalette?

        private let content: Content

        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }

        @ViewBuilder
        var body: some View {
            if let presentation {
                presentedContent(presentation)
            } else {
                content
            }
        }

        private func presentedContent(
            _ presentation: MacMusicPlaybackPresentationContext
        ) -> some View {
            content
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if showsCompactPlayer(presentation) {
                        MacMusicMiniPlayerView(
                            controller: presentation.controller,
                            engine: presentation.engine,
                            waveform: presentation.waveform,
                            artworkNamespace: presentation.artworkNamespace,
                            showNowPlaying: { setInspectorPresented(true, presentation: presentation) }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .inspector(isPresented: presentation.isInspectorPresented) {
                    MusicNowPlayingView(
                        engine: presentation.engine,
                        artworkPalette: $artworkPalette,
                        artworkNamespace: presentation.artworkNamespace,
                        onDismiss: { setInspectorPresented(false, presentation: presentation) }
                    )
                    .environment(presentation.controller)
                    .inspectorColumnWidth(min: 340, ideal: 420, max: 520)
                }
                .animation(
                    reduceMotion ? nil : .snappy,
                    value: showsCompactPlayer(presentation)
                )
        }

        private func showsCompactPlayer(
            _ presentation: MacMusicPlaybackPresentationContext
        ) -> Bool {
            presentation.controller.currentTrack != nil
                && miniPlayerVisibility?.isSuppressed != true
                && !presentation.isInspectorPresented.wrappedValue
        }

        private func setInspectorPresented(
            _ isPresented: Bool,
            presentation: MacMusicPlaybackPresentationContext
        ) {
            withAnimation(reduceMotion ? nil : .smooth(duration: isPresented ? 0.38 : 0.34)) {
                presentation.isInspectorPresented.wrappedValue = isPresented
            }
        }
    }

    #if DEBUG
        #Preview("Mac Music Playback Presentation") {
            PreviewShell(signedIn: true) {
                MacMusicPlaybackPresentationHost {
                    NavigationStack {
                        Text("Music Library")
                            .navigationTitle("Albums")
                    }
                }
            }
            .frame(width: 900, height: 680)
        }
    #endif
#endif
