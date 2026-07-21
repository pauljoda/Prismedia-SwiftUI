#if os(tvOS)
    import SwiftUI

    struct TVPlaybackOptionMenuButton: View, Equatable {
        let controller: VideoPlaybackController
        let menu: TVPlaybackOptionsMenu
        let focusTarget: TVCompatibilityPlayerFocusTarget
        let systemImage: String
        let focusedControl: FocusState<TVCompatibilityPlayerFocusTarget?>.Binding
        let onMove: (MoveCommandDirection) -> Void
        let onInteraction: () -> Void

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.controller === rhs.controller
                && lhs.menu == rhs.menu
                && lhs.focusTarget == rhs.focusTarget
                && lhs.systemImage == rhs.systemImage
        }

        var body: some View {
            Menu {
                menuActions
            } label: {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(PrismediaColor.onMedia)
                    .frame(width: 22, height: 22)
                    .padding(10)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .menuOrder(.fixed)
            .focused(focusedControl, equals: focusTarget)
            .accessibilityLabel(menu.title)
            .accessibilityIdentifier(menu.title)
            .onMoveCommand(perform: onMove)
        }

        @ViewBuilder
        private var menuActions: some View {
            switch menu {
            case .audio:
                if controller.audioChoices.isEmpty {
                    Button("Default") {}
                        .disabled(true)
                } else {
                    ForEach(controller.audioChoices) { choice in
                        optionChoice(
                            choice.title,
                            selected: controller.selectedAudioChoiceID == choice.id
                        ) {
                            Task { await controller.selectAudio(id: choice.id) }
                        }
                    }
                }
            case .subtitles:
                if controller.subtitleChoices.isEmpty {
                    Button("No Subtitles Available") {}
                        .disabled(true)
                } else {
                    ForEach(controller.subtitleChoices) { choice in
                        optionChoice(
                            choice.title,
                            selected: controller.selectedSubtitleChoiceID == choice.id
                        ) {
                            Task { await controller.selectSubtitle(id: choice.id) }
                        }
                    }
                }
            case .speed:
                ForEach(VideoPlaybackSettings.availableRates, id: \.self) { rate in
                    optionChoice(
                        VideoPlaybackSettings.label(for: rate),
                        selected: controller.playbackRate == rate
                    ) {
                        controller.setPlaybackRate(rate)
                    }
                }
            }
        }

        private func optionChoice(
            _ title: String,
            selected: Bool,
            action: @escaping () -> Void
        ) -> some View {
            Button {
                action()
                onInteraction()
            } label: {
                if selected {
                    Label(title, systemImage: "checkmark")
                } else {
                    Text(title)
                }
            }
        }
    }

    #if DEBUG
        #Preview("TV Playback Option Menu") {
            @Previewable @FocusState var focusedControl: TVCompatibilityPlayerFocusTarget?
            TVPlaybackOptionMenuButton(
                controller: VideoPlaybackController(
                    videoID: UUID(uuidString: "A57450E8-AC6C-4930-9C1E-B3995675D702")!,
                    service: VideoPlaybackPreviewService()
                ),
                menu: .subtitles,
                focusTarget: .subtitles,
                systemImage: "captions.bubble",
                focusedControl: $focusedControl,
                onMove: { _ in },
                onInteraction: {}
            )
            .equatable()
            .padding(80)
            .background(Color.black)
        }
    #endif
#endif
