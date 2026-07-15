#if os(iOS) || os(macOS)
    import SwiftUI

    struct ReaderAudiobookNowPlayingSheet: View {
        @Environment(\.dismiss) private var dismiss
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

        let controller: MusicPlayerController

        @State private var scrubPosition = 0.0
        @State private var isScrubbing = false
        @State private var selectedRate = 1.0
        @State private var isFindingReadingPosition = false
        @State private var showsReadingPositionError = false

        let onFindReadingPosition: (() async -> Bool)?

        init(
            controller: MusicPlayerController,
            onFindReadingPosition: (() async -> Bool)? = nil
        ) {
            self.controller = controller
            self.onFindReadingPosition = onFindReadingPosition
        }

        var body: some View {
            NavigationStack {
                Group {
                    if let track = controller.currentTrack {
                        ScrollView {
                            VStack(spacing: PrismediaSpacing.extraExtraLarge) {
                                artwork(track)
                                metadata(track)
                                timeline(track)
                                transport
                                partNavigation
                                if onFindReadingPosition != nil {
                                    findReadingPositionButton
                                }
                                readingSpeed
                            }
                            .frame(maxWidth: 560)
                            .padding(.horizontal, PrismediaSpacing.section)
                            .padding(.vertical, PrismediaSpacing.extraLarge)
                            .frame(maxWidth: .infinity)
                        }
                    } else {
                        ContentUnavailableView("Nothing Playing", systemImage: "headphones")
                    }
                }
                .background { PrismediaBackdrop() }
                .navigationTitle("Now Playing")
                .prismediaInlineNavigationTitle()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
            .tint(artworkPrimaryAccent)
            .task {
                scrubPosition = controller.elapsedTime
                selectedRate = Double(controller.playbackRate)
            }
            .onChange(of: controller.elapsedTime) { _, elapsedTime in
                if !isScrubbing { scrubPosition = elapsedTime }
            }
            .onChange(of: controller.currentTrack?.id) {
                scrubPosition = controller.elapsedTime
            }
            .onChange(of: controller.playbackRate) { _, playbackRate in
                let rate = Double(playbackRate)
                if selectedRate != rate { selectedRate = rate }
            }
            .onChange(of: selectedRate) { _, rate in
                controller.setPlaybackRate(Float(rate))
            }
            .alert("Couldn’t Find a Matching Page", isPresented: $showsReadingPositionError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This audiobook position could not be matched to a readable chapter.")
            }
            .accessibilityIdentifier("epub-reader.audiobook-now-playing")
        }

        private func artwork(_ track: MusicTrack) -> some View {
            EntityThumbnailArtworkFrame(aspectRatio: 1) {
                RemotePosterImage(
                    path: track.artworkPath,
                    fallbackSeed: controller.context?.playbackOwnerTitle ?? track.title,
                    systemImage: "book.closed.fill"
                )
            }
            .frame(maxWidth: 260)
            .clipShape(.rect(cornerRadius: PrismediaRadius.control))
            .shadow(color: .black.opacity(0.24), radius: 20, y: 10)
            .accessibilityHidden(true)
        }

        private func metadata(_ track: MusicTrack) -> some View {
            VStack(spacing: PrismediaSpacing.extraSmall) {
                Text(track.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .lineLimit(3)

                if let bookTitle = controller.context?.playbackOwnerTitle {
                    Text(bookTitle)
                        .font(.body)
                        .foregroundStyle(PrismediaColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .accessibilityElement(children: .combine)
        }

        private func timeline(_ track: MusicTrack) -> some View {
            MusicPlaybackTimeline(
                position: $scrubPosition,
                duration: max(track.duration ?? 0, controller.elapsedTime, 1),
                onEditingChanged: scrubDidChange
            )
        }

        private var transport: some View {
            HStack(spacing: 44) {
                Button("Back 15 Seconds", systemImage: "gobackward.15") {
                    seek(by: -15)
                }
                .labelStyle(.iconOnly)

                Button(
                    controller.isPlaying ? "Pause" : "Play",
                    systemImage: controller.isPlaying ? "pause.fill" : "play.fill",
                    action: togglePlayback
                )
                .labelStyle(.iconOnly)
                .font(.system(size: 34, weight: .bold))
                .frame(width: 64, height: 64)
                .contentTransition(.identity)

                Button("Forward 30 Seconds", systemImage: "goforward.30") {
                    seek(by: 30)
                }
                .labelStyle(.iconOnly)
            }
            .font(.system(size: 25, weight: .semibold))
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
        }

        private var partNavigation: some View {
            HStack(spacing: PrismediaSpacing.medium) {
                Button("Previous Part", systemImage: "backward.end.fill", action: controller.skipToPrevious)
                    .frame(maxWidth: .infinity)
                    .disabled(!controller.queue.canGoPrevious)

                Button("Next Part", systemImage: "forward.end.fill", action: controller.skipToNext)
                    .frame(maxWidth: .infinity)
                    .disabled(!controller.queue.canGoNext)
            }
            .buttonStyle(.glass(.clear))
            .buttonBorderShape(.capsule)
        }

        private var findReadingPositionButton: some View {
            Button(action: findReadingPosition) {
                HStack(spacing: PrismediaSpacing.medium) {
                    if isFindingReadingPosition {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "book.pages")
                            .foregroundStyle(artworkPrimaryAccent)
                    }

                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                        Text("Attempt to Find This Passage")
                            .font(.headline)
                        Text(
                            "Prismedia will estimate the matching page from your current audiobook position."
                        )
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)
                        .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.glass(.clear))
            .buttonBorderShape(.roundedRectangle(radius: PrismediaRadius.control))
            .disabled(isFindingReadingPosition)
            .accessibilityIdentifier("epub-reader.audiobook-find-page")
        }

        private var readingSpeed: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                LabeledContent("Reading Speed") {
                    Text(MusicPlaybackRateOption(rate: Float(selectedRate)).label)
                        .monospacedDigit()
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
                .font(.headline)

                Slider(value: $selectedRate, in: 0.5...2, step: 0.25) {
                    Text("Reading Speed")
                } minimumValueLabel: {
                    Text("0.5×")
                } maximumValueLabel: {
                    Text("2×")
                }
                .accessibilityValue(MusicPlaybackRateOption(rate: Float(selectedRate)).label)

                HStack {
                    ForEach(MusicPlaybackRateOption.standard) { option in
                        Text(option.label)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(
                                option.rate == Float(selectedRate)
                                    ? artworkPrimaryAccent
                                    : PrismediaColor.textMuted
                            )
                        if option.id != MusicPlaybackRateOption.standard.last?.id {
                            Spacer(minLength: 0)
                        }
                    }
                }
                .accessibilityHidden(true)
            }
            .padding(PrismediaSpacing.large)
            .background(
                PrismediaColor.groupedContentBackground,
                in: .rect(cornerRadius: PrismediaRadius.control)
            )
        }

        private func scrubDidChange(_ editing: Bool) {
            isScrubbing = editing
            if !editing { controller.seek(to: scrubPosition) }
        }

        private func seek(by seconds: Double) {
            guard let track = controller.currentTrack else { return }
            let destination = max(0, controller.elapsedTime + seconds)
            guard let duration = track.duration, duration > 0 else {
                controller.seek(to: destination)
                return
            }
            controller.seek(to: min(destination, duration))
        }

        private func togglePlayback() {
            withoutMusicControlAnimation {
                controller.isPlaying ? controller.pause() : controller.resume()
            }
        }

        private func findReadingPosition() {
            guard let onFindReadingPosition, !isFindingReadingPosition else { return }
            isFindingReadingPosition = true
            Task {
                let didFind = await onFindReadingPosition()
                isFindingReadingPosition = false
                if didFind {
                    dismiss()
                } else {
                    showsReadingPositionError = true
                }
            }
        }
    }

    #if DEBUG
        #Preview("Reader Audiobook Now Playing") {
            ReaderAudiobookNowPlayingSheet(
                controller: MusicPreviewData.controller(),
                onFindReadingPosition: { true }
            )
            .preferredColorScheme(.dark)
        }
    #endif
#endif
