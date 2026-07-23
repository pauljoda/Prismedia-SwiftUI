#if os(iOS)
    import SwiftUI

    struct MusicNowPlayingControlBar: View {
        @Environment(MusicPlayerController.self) private var controller

        let presentation: MusicNowPlayingPresentation
        let onToggleQueue: () -> Void

        var body: some View {
            PrismediaGlassButtonGroup(spacing: PrismediaSpacing.medium) {
                MusicRoutePicker()
                    .glassEffect(.regular.interactive(), in: .circle)
                    .accessibilityLabel("Choose Audio Output")

                HStack(spacing: PrismediaSpacing.large) {
                    shuffleButton
                    repeatButton
                }
                .frame(maxWidth: .infinity)

                queueButton
            }
        }

        private var shuffleButton: some View {
            shuffleControl
                .buttonStyle(.glass)
        }

        private var repeatButton: some View {
            repeatControl
                .buttonStyle(.glass)
        }

        private var shuffleControl: some View {
            Button {
                withoutMusicControlAnimation {
                    controller.setShuffleEnabled(!controller.queue.isShuffled)
                }
            } label: {
                Image(
                    systemName: controller.queue.isShuffled
                        ? "shuffle.circle.fill"
                        : "shuffle"
                )
                .padding(PrismediaSpacing.small)
                .frame(maxWidth: .infinity)
            }
            .buttonBorderShape(.capsule)
            .disabled(controller.context?.isAudiobook == true)
            .accessibilityLabel(shuffleLabel)
            .accessibilityValue(controller.queue.isShuffled ? "On" : "Off")
            .accessibilityIdentifier("music.shuffle")
        }

        private var repeatControl: some View {
            Button {
                withoutMusicControlAnimation(controller.cycleRepeatMode)
            } label: {
                Image(systemName: repeatSystemImage)
                    .padding(PrismediaSpacing.small)
                    .frame(maxWidth: .infinity)
            }
            .buttonBorderShape(.capsule)
            .accessibilityLabel(repeatLabel)
            .accessibilityValue(repeatValue)
            .accessibilityIdentifier("music.repeat")
        }

        private var queueButton: some View {
            Button(action: onToggleQueue) {
                Image(
                    systemName: presentation == .queue
                        ? "list.bullet.circle.fill"
                        : "list.bullet"
                )
                .padding(PrismediaSpacing.small)
            }
            .buttonBorderShape(.circle)
            .buttonStyle(.glass)
            .accessibilityLabel(presentation == .queue ? "Show Now Playing" : "Show Queue")
            .accessibilityIdentifier("music.queue-button")
        }

        private var shuffleLabel: String {
            if controller.context?.isAudiobook == true {
                return "Shuffle unavailable. Audiobook parts play in order"
            }
            return controller.queue.isShuffled ? "Turn Shuffle Off" : "Turn Shuffle On"
        }

        private var repeatSystemImage: String {
            switch controller.queue.repeatMode {
            case .off: "repeat"
            case .all: "repeat.circle.fill"
            case .one: "repeat.1.circle.fill"
            }
        }

        private var repeatLabel: String {
            switch controller.queue.repeatMode {
            case .off: "Set Repeat All"
            case .all: "Set Repeat One"
            case .one: "Turn Repeat Off"
            }
        }

        private var repeatValue: String {
            switch controller.queue.repeatMode {
            case .off: "Off"
            case .all: "All"
            case .one: "One"
            }
        }
    }

    #if DEBUG
        #Preview("Now Playing Controls") {
            @Previewable @State var controller = MusicPreviewData.controller()
            MusicNowPlayingControlBar(
                presentation: .player,
                onToggleQueue: {}
            )
            .environment(controller)
            .padding()
            .background(PrismediaBackdrop())
        }
    #endif
#endif
