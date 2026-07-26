#if os(macOS)
    import SwiftUI

    struct MacMusicCompactTransportView: View {
        let controller: MusicPlayerController
        let accent: Color

        var body: some View {
            HStack(spacing: PrismediaSpacing.extraExtraSmall) {
                control(
                    controller.queue.isShuffled ? "Turn Shuffle Off" : "Turn Shuffle On",
                    systemImage: "shuffle",
                    isActive: controller.queue.isShuffled,
                    isDisabled: controller.context?.isAudiobook == true
                ) {
                    withoutMusicControlAnimation {
                        controller.setShuffleEnabled(!controller.queue.isShuffled)
                    }
                }

                control(
                    "Previous Track",
                    systemImage: "backward.fill",
                    isDisabled: !controller.queue.canGoPrevious,
                    action: controller.skipToPrevious
                )

                Button(action: togglePlayback) {
                    Image(systemName: controller.isPlaying ? "pause.fill" : "play.fill")
                        .font(.body.weight(.bold))
                        .foregroundStyle(PrismediaColor.background)
                        .frame(width: 34, height: 34)
                        .background(accent.opacity(0.88), in: Circle())
                        .contentShape(.circle)
                }
                .frame(width: 38, height: 38)
                .contentShape(.rect)
                .accessibilityLabel(controller.isPlaying ? "Pause" : "Play")
                .contentTransition(.identity)
                .animation(nil, value: controller.isPlaying)

                control(
                    "Next Track",
                    systemImage: "forward.fill",
                    isDisabled: !controller.queue.canGoNext,
                    action: controller.skipToNext
                )

                control(
                    repeatLabel,
                    systemImage: controller.queue.repeatMode == .one ? "repeat.1" : "repeat",
                    isActive: controller.queue.repeatMode != .off,
                    action: { withoutMusicControlAnimation(controller.cycleRepeatMode) }
                )
            }
        }

        private func control(
            _ title: String,
            systemImage: String,
            isActive: Bool = false,
            isDisabled: Bool = false,
            action: @escaping () -> Void
        ) -> some View {
            Button(title, systemImage: systemImage, action: action)
                .labelStyle(.iconOnly)
                .font(.callout.weight(.semibold))
                .foregroundStyle(isActive ? accent.opacity(0.82) : PrismediaColor.textSecondary)
                .frame(
                    width: PrismediaLayout.minimumHitTarget,
                    height: PrismediaLayout.minimumHitTarget
                )
                .contentShape(.rect)
                .disabled(isDisabled)
        }

        private var repeatLabel: String {
            switch controller.queue.repeatMode {
            case .off: "Set Repeat All"
            case .all: "Set Repeat One"
            case .one: "Turn Repeat Off"
            }
        }

        private func togglePlayback() {
            withoutMusicControlAnimation {
                controller.isPlaying ? controller.pause() : controller.resume()
            }
        }
    }

    #if DEBUG
        #Preview("Mac Compact Transport") {
            @Previewable @State var controller = MusicPreviewData.controller()

            PreviewShell(signedIn: true) {
                MacMusicCompactTransportView(
                    controller: controller,
                    accent: PrismediaColor.materialSpectrumGreen
                )
                .padding()
            }
        }
    #endif
#endif
