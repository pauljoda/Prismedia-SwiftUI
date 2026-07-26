#if os(macOS)
    import AVFoundation
    import SwiftUI

    struct MacMusicCompactUtilityControls: View {
        @State private var volume = 1.0
        @State private var showsVolume = false

        let controller: MusicPlayerController
        let engine: AVPlayerAudioPlaybackEngine
        let showNowPlaying: () -> Void
        let hidePlayer: () -> Void

        var body: some View {
            HStack(spacing: PrismediaSpacing.extraExtraSmall) {
                Menu("More", systemImage: "ellipsis") {
                    Button("Show Now Playing", systemImage: "sidebar.trailing", action: showNowPlaying)
                    Divider()
                    Button("Hide Player", systemImage: "xmark", action: hidePlayer)
                }
                .menuIndicator(.hidden)
                .labelStyle(.iconOnly)
                .help("More")

                Button("Show Now Playing", systemImage: "sidebar.trailing", action: showNowPlaying)
                    .labelStyle(.iconOnly)
                    .help("Show Now Playing Inspector")

                Button(
                    volume <= 0 ? "Muted" : "Volume",
                    systemImage: volumeSystemImage
                ) {
                    showsVolume.toggle()
                }
                .labelStyle(.iconOnly)
                .help("Volume")
                .popover(isPresented: $showsVolume, arrowEdge: .bottom) {
                    HStack(spacing: PrismediaSpacing.medium) {
                        Image(systemName: "speaker.fill")
                        Slider(value: $volume, in: 0...1)
                            .accessibilityLabel("Volume")
                        Image(systemName: "speaker.wave.3.fill")
                    }
                    .foregroundStyle(PrismediaColor.textSecondary)
                    .padding(PrismediaSpacing.large)
                    .frame(width: 240)
                }
            }
            .font(.callout.weight(.semibold))
            .foregroundStyle(PrismediaColor.textSecondary)
            .onAppear { volume = Double(engine.player.volume) }
            .onChange(of: volume) { _, value in
                engine.player.volume = Float(min(max(value, 0), 1))
            }
        }

        private var volumeSystemImage: String {
            switch volume {
            case ...0: "speaker.slash.fill"
            case ..<0.34: "speaker.wave.1.fill"
            case ..<0.67: "speaker.wave.2.fill"
            default: "speaker.wave.3.fill"
            }
        }
    }

    #if DEBUG
        #Preview("Mac Compact Utilities") {
            @Previewable @State var controller = MusicPreviewData.controller()
            @Previewable @State var engine = AVPlayerAudioPlaybackEngine()

            PreviewShell(signedIn: true) {
                MacMusicCompactUtilityControls(
                    controller: controller,
                    engine: engine,
                    showNowPlaying: {},
                    hidePlayer: {}
                )
                .padding()
            }
        }
    #endif
#endif
