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
                .overlay(alignment: .bottom) {
                    if showsCompactPlayer(presentation) {
                        MacMusicMiniPlayerView(
                            controller: presentation.controller,
                            engine: presentation.engine,
                            waveform: presentation.waveform,
                            artworkPalette: $artworkPalette,
                            showNowPlaying: { setInspectorPresented(true, presentation: presentation) }
                        )
                        .transition(
                            .scale(scale: 1.08, anchor: .bottomTrailing)
                                .combined(with: .opacity)
                        )
                    }
                }
                .inspector(isPresented: inspectorBinding(presentation)) {
                    MusicNowPlayingView(
                        engine: presentation.engine,
                        artworkPalette: $artworkPalette,
                        onDismiss: { setInspectorPresented(false, presentation: presentation) }
                    )
                    .environment(presentation.controller)
                    .inspectorColumnWidth(min: 340, ideal: 420, max: 520)
                }
        }

        private func showsCompactPlayer(
            _ presentation: MacMusicPlaybackPresentationContext
        ) -> Bool {
            presentation.controller.currentTrack != nil
                && miniPlayerVisibility?.isSuppressed != true
                && !presentation.isInspectorPresented.wrappedValue
        }

        private func inspectorBinding(
            _ presentation: MacMusicPlaybackPresentationContext
        ) -> Binding<Bool> {
            Binding(
                get: { presentation.isInspectorPresented.wrappedValue },
                set: { setInspectorPresented($0, presentation: presentation) }
            )
        }

        private func setInspectorPresented(
            _ isPresented: Bool,
            presentation: MacMusicPlaybackPresentationContext
        ) {
            guard isPresented != presentation.isInspectorPresented.wrappedValue else { return }
            if reduceMotion {
                presentation.isInspectorPresented.wrappedValue = isPresented
                return
            }
            withAnimation(.smooth(duration: 0.38)) {
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
