#if os(iOS) || os(macOS)
    import SwiftUI

    struct ReaderAudiobookNowPlayingSheet: View {
        @Environment(\.dismiss) private var dismiss
        @Environment(\.artworkPalette) private var artworkPalette
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

        let controller: MusicPlayerController

        @State private var scrubPosition = 0.0
        @State private var isScrubbing = false
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
                        VStack(spacing: 0) {
                            VStack(spacing: PrismediaSpacing.extraLarge) {
                                artwork(track)
                                metadata(track)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .layoutPriority(1)

                            timeline
                                .padding(.horizontal, PrismediaSpacing.section)

                            transport

                            MusicPlaybackRateControl(controller: controller)
                                .padding(.horizontal, PrismediaSpacing.section)
                                .padding(.top, PrismediaSpacing.extraLarge)
                                .padding(.bottom, PrismediaSpacing.medium)

                            readerControls
                                .padding(.top, PrismediaSpacing.small)
                                .padding(.horizontal, PrismediaSpacing.extraLarge)
                                .padding(.bottom, PrismediaSpacing.medium)
                        }
                    } else {
                        ContentUnavailableView("Nothing Playing", systemImage: "headphones")
                    }
                }
                .prismediaScreenBackground(palette: artworkPalette)
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
            }
            .onChange(of: controller.elapsedTime) { _, elapsedTime in
                if !isScrubbing { scrubPosition = elapsedTime }
            }
            .onChange(of: controller.currentTrack?.id) {
                scrubPosition = controller.elapsedTime
            }
            .alert("Couldn’t Find a Matching Page", isPresented: $showsReadingPositionError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This audiobook position could not be matched to a readable chapter.")
            }
            .accessibilityIdentifier("epub-reader.audiobook-now-playing")
        }

        private func artwork(_ track: MusicTrack) -> some View {
            GeometryReader { geometry in
                let artworkSize = fittedArtworkSize(in: geometry.size)

                MusicNowPlayingArtwork(
                    track: track,
                    aspectRatio: artworkAspectRatio,
                    fallbackSeed: controller.context?.playbackOwnerTitle,
                    systemImage: artworkSystemImage
                )
                .frame(width: artworkSize.width, height: artworkSize.height)
                .compositingGroup()
                .clipShape(.rect(cornerRadius: PrismediaRadius.control))
                .shadow(color: .black.opacity(0.4), radius: 24, y: 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .layoutPriority(1)
            .accessibilityHidden(true)
        }

        private func metadata(_ track: MusicTrack) -> some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Text(track.title)
                    .font(.title3.bold())
                    .lineLimit(1)

                if let bookTitle = controller.context?.playbackOwnerTitle {
                    Text(bookTitle)
                        .font(.body)
                        .foregroundStyle(PrismediaColor.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, PrismediaSpacing.section)
            .accessibilityElement(children: .combine)
        }

        private var timeline: some View {
            MusicPlaybackTimeline(
                position: $scrubPosition,
                duration: controller.currentTrackDuration,
                onEditingChanged: scrubDidChange
            )
        }

        private var transport: some View {
            HStack(spacing: 54) {
                Button("Back 15 Seconds", systemImage: "gobackward.15") {
                    seek(by: -15)
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(artworkPrimaryAccent.opacity(0.78))

                Button(
                    controller.isPlaying ? "Pause" : "Play",
                    systemImage: controller.isPlaying ? "pause.fill" : "play.fill",
                    action: togglePlayback
                )
                .labelStyle(.iconOnly)
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(artworkPrimaryAccent)
                .frame(width: 64, height: 64)
                .contentTransition(.identity)
                .animation(nil, value: controller.isPlaying)

                Button("Forward 30 Seconds", systemImage: "goforward.30") {
                    seek(by: 30)
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(artworkPrimaryAccent.opacity(0.78))
            }
            .font(.system(size: 27, weight: .semibold))
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .padding(.top, PrismediaSpacing.large)
        }

        private var readerControls: some View {
            PrismediaGlassButtonGroup(spacing: PrismediaSpacing.medium) {
                Button("Previous Part", systemImage: "backward.end.fill", action: controller.skipToPrevious)
                    .labelStyle(.iconOnly)
                    .padding(PrismediaSpacing.small)
                    .disabled(!controller.queue.canGoPrevious)
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)

                if onFindReadingPosition != nil {
                    Button(action: findReadingPosition) {
                        HStack(spacing: PrismediaSpacing.small) {
                            if isFindingReadingPosition {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "book.pages")
                            }
                            Text("Find Page")
                                .font(.headline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .padding(.horizontal, PrismediaSpacing.small)
                        .padding(.vertical, PrismediaSpacing.extraSmall)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.capsule)
                    .tint(artworkPrimaryAccent)
                    .foregroundStyle(PrismediaColor.onAccent)
                    .disabled(isFindingReadingPosition)
                    .accessibilityLabel("Attempt to Find This Passage")
                    .accessibilityHint(
                        "Estimates the matching page from the current audiobook position"
                    )
                    .accessibilityIdentifier("epub-reader.audiobook-find-page")
                } else {
                    Spacer(minLength: 0)
                }

                Button("Next Part", systemImage: "forward.end.fill", action: controller.skipToNext)
                    .labelStyle(.iconOnly)
                    .padding(PrismediaSpacing.small)
                    .disabled(!controller.queue.canGoNext)
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
            }
        }

        private var artworkAspectRatio: Double {
            controller.context?.playbackOwnerEntityKind?.thumbnailAspectRatio
                ?? EntityKind.book.thumbnailAspectRatio
        }

        private var artworkSystemImage: String {
            controller.context?.playbackOwnerEntityKind?.thumbnailFallbackSystemImage
                ?? EntityKind.book.thumbnailFallbackSystemImage
        }

        private func fittedArtworkSize(in availableSize: CGSize) -> CGSize {
            let availableWidth = max(1, availableSize.width - (PrismediaSpacing.section * 2))
            let width = max(1, min(availableWidth, 280, availableSize.height * artworkAspectRatio))
            return CGSize(width: width, height: width / artworkAspectRatio)
        }

        private func scrubDidChange(_ editing: Bool) {
            isScrubbing = editing
            if !editing { controller.seek(to: scrubPosition) }
        }

        private func seek(by seconds: Double) {
            guard controller.currentTrack != nil else { return }
            let destination = max(0, controller.elapsedTime + seconds)
            controller.seek(to: min(destination, controller.currentTrackDuration))
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
                controller: MusicPreviewData.audiobookController(),
                onFindReadingPosition: { true }
            )
            .preferredColorScheme(.dark)
        }
    #endif
#endif
