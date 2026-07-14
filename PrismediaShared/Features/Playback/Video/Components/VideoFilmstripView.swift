import AVFoundation
import ImageIO
import SwiftUI

#if !os(tvOS)

    struct VideoFilmstripView: View {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
        let playlistPath: String
        let service: any VideoPlaybackServicing
        let controller: VideoPlaybackController
        let markers: [EntityMarker]
        let onInitialLoadCompleted: (Bool) -> Void

        @State private var frames: [TrickplayPlaylist.Frame] = []
        @State private var dragStartTime: Double?
        @State private var previewTime: Double?
        @State private var inertiaTask: Task<Void, Never>?
        @State private var scrubGeneration = 0

        private let stripHeight: CGFloat = 52
        private let frameWidth: CGFloat = 92
        private let visibleRadius = 8

        var body: some View {
            Group {
                if frames.isEmpty {
                    loadingPlaceholder
                } else {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !controller.isPlaying)) { _ in
                        strip(at: displayedTime)
                    }
                }
            }
            .frame(height: stripHeight)
            .background(Color.black)
            .clipped()
            .task(id: playlistPath) { await loadFrames() }
            .onDisappear { inertiaTask?.cancel() }
        }

        private var loadingPlaceholder: some View {
            ZStack {
                Color(white: 0.035)
                ProgressView()
                    .controlSize(.small)
                    .tint(artworkPrimaryAccent)
            }
        }

        private var displayedTime: Double {
            if let previewTime { return previewTime }
            let liveTime = controller.player.currentTime().seconds
            return liveTime.isFinite ? max(0, liveTime) : controller.currentTime
        }

        private func strip(at activeTime: Double) -> some View {
            HStack(spacing: 0) {
                jumpButton(direction: -1, systemImage: "chevron.left", activeTime: activeTime)
                GeometryReader { geometry in
                    ZStack {
                        filmTrack(width: geometry.size.width, activeTime: activeTime)
                        edgeFades
                        playhead
                    }
                    .contentShape(Rectangle())
                    .gesture(scrubGesture(trackWidth: CGFloat(frames.count) * frameWidth, activeTime: activeTime))
                    .clipped()
                }
                jumpButton(direction: 1, systemImage: "chevron.right", activeTime: activeTime)
            }
        }

        private func filmTrack(width: CGFloat, activeTime: Double) -> some View {
            let continuousIndex = VideoFilmstripLayout.continuousIndex(
                at: activeTime,
                frames: frames,
                duration: controller.duration
            )
            let visibleIndexes = VideoFilmstripLayout.visibleIndexes(
                at: continuousIndex,
                frameCount: frames.count,
                radius: visibleRadius
            )

            return ZStack(alignment: .topLeading) {
                ForEach(visibleIndexes, id: \.self) { index in
                    let frame = frames[index]
                    SpriteFrameView(
                        frame: frame,
                        imageURL: service.authenticatedMediaURL(for: frame.imageURL.absoluteString) ?? frame.imageURL
                    )
                    .frame(width: frameWidth, height: stripHeight)
                    .offset(x: width / 2 + CGFloat(Double(index) - continuousIndex) * frameWidth)
                }

                ForEach(markers, id: \.id) { marker in
                    let markerIndex = VideoFilmstripLayout.continuousIndex(
                        at: marker.seconds,
                        frames: frames,
                        duration: controller.duration
                    )
                    Button {
                        cancelScrub()
                        controller.seek(to: marker.seconds)
                    } label: {
                        ZStack {
                            Color.clear
                            Rectangle()
                                .fill(artworkPrimaryAccent.opacity(0.65))
                                .frame(width: 1, height: stripHeight)
                        }
                        .frame(width: PrismediaLayout.minimumHitTarget, height: stripHeight)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .offset(
                        x: width / 2
                            + CGFloat(markerIndex - continuousIndex) * frameWidth
                            - 22
                    )
                    .accessibilityLabel(marker.title)
                    .accessibilityValue("At \(VideoPlaybackPresentation.clockTime(marker.seconds))")
                    .accessibilityHint("Seeks playback to this marker")
                    .accessibilityIdentifier("video-filmstrip.marker.\(marker.id)")
                }
            }
        }

        private var edgeFades: some View {
            HStack {
                LinearGradient(colors: [.black.opacity(0.72), .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: 56)
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.72)], startPoint: .leading, endPoint: .trailing)
                    .frame(width: 56)
            }
            .allowsHitTesting(false)
        }

        private var playhead: some View {
            Rectangle()
                .fill(artworkPrimaryAccent)
                .frame(width: 2, height: stripHeight)
                .shadow(color: artworkPrimaryAccent.opacity(0.72), radius: 4)
                .frame(maxWidth: .infinity)
                .allowsHitTesting(false)
                .accessibilityIdentifier("video-filmstrip.playhead")
        }

        private func jumpButton(direction: Int, systemImage: String, activeTime: Double) -> some View {
            Button {
                cancelScrub()
                let index = frameIndex(at: activeTime)
                let next = max(0, min(frames.count - 1, index + direction))
                controller.seek(to: frames[next].startTime)
            } label: {
                Image(systemName: systemImage)
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: PrismediaLayout.minimumHitTarget, height: stripHeight)
                    .background(Color.black.opacity(0.9))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(direction < 0 ? "Previous frame" : "Next frame")
            .accessibilityHint("Seeks playback by one preview frame")
        }

        private func scrubGesture(trackWidth: CGFloat, activeTime: Double) -> some Gesture {
            DragGesture(minimumDistance: 2)
                .onChanged { value in
                    let wasCoasting = inertiaTask != nil
                    inertiaTask?.cancel()
                    inertiaTask = nil
                    if wasCoasting {
                        dragStartTime = activeTime
                        scrubGeneration += 1
                    }
                    let start = dragStartTime ?? activeTime
                    if dragStartTime == nil {
                        dragStartTime = start
                        scrubGeneration += 1
                    }
                    let delta =
                        trackWidth > 0
                        ? -Double(value.translation.width / trackWidth) * controller.duration
                        : 0
                    previewTime = max(0, min(controller.duration, start + delta))
                }
                .onEnded { value in
                    let start = dragStartTime ?? activeTime
                    let releasedTime = previewTime ?? activeTime
                    let projectedTime = VideoFilmstripLayout.projectedTime(
                        from: start,
                        predictedTranslation: value.predictedEndTranslation.width,
                        trackWidth: trackWidth,
                        duration: controller.duration
                    )
                    beginInertia(from: releasedTime, to: projectedTime)
                }
        }

        private func beginInertia(from start: Double, to target: Double) {
            inertiaTask?.cancel()
            let generation = scrubGeneration
            guard abs(target - start) > 0.05 else {
                commitSeek(to: start, generation: generation)
                return
            }
            inertiaTask = Task { @MainActor in
                let steps = 20
                for step in 1...steps {
                    guard !Task.isCancelled else { return }
                    let progress = Double(step) / Double(steps)
                    let eased = 1 - pow(1 - progress, 3)
                    previewTime = start + (target - start) * eased
                    do {
                        try await Task.sleep(for: .milliseconds(16))
                    } catch {
                        return
                    }
                }
                guard !Task.isCancelled else { return }
                commitSeek(to: target, generation: generation)
            }
        }

        private func commitSeek(to target: Double, generation: Int) {
            previewTime = target
            controller.seek(to: target) { _ in
                guard generation == scrubGeneration else { return }
                previewTime = nil
                dragStartTime = nil
                inertiaTask = nil
            }
        }

        private func cancelScrub() {
            scrubGeneration += 1
            inertiaTask?.cancel()
            inertiaTask = nil
            previewTime = nil
            dragStartTime = nil
        }

        private func frameIndex(at time: Double) -> Int {
            frames.lastIndex(where: { $0.startTime <= time }) ?? 0
        }

        private func loadFrames() async {
            do {
                let data = try await service.mediaData(for: playlistPath)
                guard
                    let contents = String(data: data, encoding: .utf8),
                    let playlistURL = service.authenticatedMediaURL(for: playlistPath)
                else {
                    onInitialLoadCompleted(false)
                    return
                }
                let loadedFrames = try TrickplayPlaylist.parse(contents: contents, playlistURL: playlistURL).frames
                guard !loadedFrames.isEmpty else {
                    onInitialLoadCompleted(false)
                    return
                }

                let initialIndex = VideoFilmstripLayout.continuousIndex(
                    at: controller.currentTime, frames: loadedFrames)
                let spriteURLs = VideoFilmstripLayout.spriteURLsToPrewarm(
                    at: initialIndex,
                    frames: loadedFrames,
                    radius: visibleRadius
                ).map { service.authenticatedMediaURL(for: $0.absoluteString) ?? $0 }
                let loadedSprites = try await withThrowingTaskGroup(
                    of: (URL, Data).self,
                    returning: [(URL, Data)].self
                ) { group in
                    for spriteURL in spriteURLs {
                        group.addTask {
                            (spriteURL, try await RemoteArtworkPipeline.shared.data(for: spriteURL))
                        }
                    }
                    var loaded: [(URL, Data)] = []
                    for try await sprite in group { loaded.append(sprite) }
                    return loaded
                }
                for (spriteURL, spriteData) in loadedSprites {
                    guard
                        await TrickplaySpriteImageCache.shared.image(
                            for: spriteURL,
                            data: spriteData
                        ) != nil
                    else {
                        throw VideoFilmstripLoadingError.invalidSprite
                    }
                }
                guard !Task.isCancelled else { return }
                frames = loadedFrames
                onInitialLoadCompleted(true)
            } catch is CancellationError {
                return
            } catch {
                frames = []
                onInitialLoadCompleted(false)
            }
        }
    }
#endif

#if DEBUG
    #if !os(tvOS)
        #Preview("Video Filmstrip · Loading") {
            let service = VideoPlaybackPreviewService()
            let controller = VideoPlaybackController(
                videoID: UUID(uuidString: "A57450E8-AC6C-4930-9C1E-B3995675D702")!,
                service: service
            )

            VideoFilmstripView(
                playlistPath: "https://example.invalid/trickplay/manifest.m3u8",
                service: service,
                controller: controller,
                markers: [],
                onInitialLoadCompleted: { _ in }
            )
            .frame(width: 720)
        }
    #endif
#endif
