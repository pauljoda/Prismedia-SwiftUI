import SwiftUI

public struct EntityThumbnailMediaView: View {
    @Environment(PrismediaAppEnvironment.self) private var environment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var activeRatio: Double?
    @State private var spriteFrames: [TrickplayPlaylist.Frame] = []
    @State private var spriteLoadFailed = false
    @State private var isPressPreviewing = false
    @State private var pressPreviewTask: Task<Void, Never>?
    @State private var pendingHoverRatio: Double?
    @State private var hoverIntentTask: Task<Void, Never>?

    private let item: EntityThumbnail
    private let preview: EntityThumbnailPreview
    private let systemImage: String
    private let contentMode: ContentMode
    private let onPreviewHoldChanged: (Bool) -> Void

    public init(
        item: EntityThumbnail,
        systemImage: String,
        contentMode: ContentMode,
        onPreviewHoldChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.item = item
        preview = EntityThumbnailPreview(thumbnail: item)
        self.systemImage = systemImage
        self.contentMode = contentMode
        self.onPreviewHoldChanged = onPreviewHoldChanged
    }

    public var body: some View {
        Group {
            #if os(macOS)
                GeometryReader { geometry in
                    interactiveContent(width: geometry.size.width)
                }
            #else
                interactiveContent(width: 0)
            #endif
        }
        .task(id: spriteLoadRequestID) {
            guard let spriteLoadRequestID else { return }
            await loadSpriteFrames(from: spriteLoadRequestID)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Artwork preview")
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(accessibilityHint)
        .accessibilityAdjustableAction(adjustPreview)
        .onDisappear { endInteractivePreview() }
    }

    @ViewBuilder
    private func interactiveContent(width: CGFloat) -> some View {
        #if os(macOS)
            content
                .contentShape(Rectangle())
                .onContinuousHover(coordinateSpace: .local) { phase in
                    handleHover(phase, width: width)
                }
        #elseif os(iOS)
            content
                .contentShape(Rectangle())
                .onLongPressGesture(
                    minimumDuration: 0.45,
                    maximumDistance: 18,
                    perform: beginPressPreview,
                    onPressingChanged: pressStateDidChange
                )
        #else
            content
                .contentShape(Rectangle())
        #endif
    }

    private var content: some View {
        ZStack {
            RemotePosterImage(
                path: displayedArtworkPath,
                previewPath: preview.restingArtworkPath,
                fallbackSeed: item.title,
                systemImage: systemImage,
                contentMode: contentMode,
                maxPixelSize: 512
            )

            if let activeSpriteFrame {
                SpriteFrameView(
                    frame: activeSpriteFrame,
                    imageURL: authenticatedURL(for: activeSpriteFrame.imageURL)
                )
                .id(spriteFrameIdentity(activeSpriteFrame))
                .transition(.opacity)
            }
        }
        .overlay(alignment: .bottom) {
            if preview.imageOptions.count > 1 {
                EntityThumbnailSegmentRail(
                    options: preview.imageOptions,
                    activeIndex: activeImageIndex
                )
                .padding(PrismediaSpacing.small)
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: displayedPreviewIdentity)
    }

    private var displayedArtworkPath: String? {
        guard let activeImageIndex else { return preview.restingArtworkPath }
        return preview.imageOptions[activeImageIndex].path
    }

    private var activeImageIndex: Int? {
        guard let activeRatio else { return nil }
        return EntityThumbnailPreview.index(for: activeRatio, count: preview.imageOptions.count)
    }

    private var activeSpriteIndex: Int? {
        guard let activeRatio else { return nil }
        return EntityThumbnailPreview.index(for: activeRatio, count: spriteFrames.count)
    }

    private var activeSpriteFrame: TrickplayPlaylist.Frame? {
        guard let activeSpriteIndex else { return nil }
        return spriteFrames[activeSpriteIndex]
    }

    private var displayedPreviewIdentity: String {
        if let activeSpriteIndex { return "sprite:\(activeSpriteIndex)" }
        if let activeImageIndex { return "image:\(activeImageIndex)" }
        return "cover"
    }

    private var spriteLoadRequestID: String? {
        guard activeRatio != nil, spriteFrames.isEmpty, !spriteLoadFailed else { return nil }
        return preview.spritePlaylistPath
    }

    private var accessibilityValue: String {
        if preview.kind == .imageSequence {
            return preview.accessibilityValue(at: activeImageIndex)
        }
        guard let activeSpriteIndex else { return "Cover" }
        return "Preview \(activeSpriteIndex + 1) of \(spriteFrames.count)"
    }

    private var accessibilityHint: String {
        guard preview.hasInteractivePreview else { return "" }
        #if os(macOS)
            return "Move the pointer across the artwork to preview."
        #elseif os(iOS)
            return "Touch and hold to play previews. Swipe up or down with VoiceOver to move one at a time."
        #else
            return "Swipe up or down with VoiceOver to move through artwork previews."
        #endif
    }

    #if os(macOS)
        private func handleHover(_ phase: HoverPhase, width: CGFloat) {
            switch phase {
            case .active(let location):
                let ratio = EntityThumbnailPreview.ratio(
                    location: Double(location.x),
                    width: Double(width)
                )
                pendingHoverRatio = ratio
                if activeRatio != nil {
                    activeRatio = ratio
                } else if hoverIntentTask == nil {
                    hoverIntentTask = Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(140))
                        guard !Task.isCancelled else { return }
                        activeRatio = pendingHoverRatio
                        hoverIntentTask = nil
                    }
                }
            case .ended:
                hoverIntentTask?.cancel()
                hoverIntentTask = nil
                pendingHoverRatio = nil
                activeRatio = nil
            }
        }
    #endif

    #if os(iOS)
        private func pressStateDidChange(_ isPressing: Bool) {
            if !isPressing { endPressPreview() }
        }

        private func beginPressPreview() {
            guard preview.hasInteractivePreview, !isPressPreviewing else { return }
            isPressPreviewing = true
            onPreviewHoldChanged(true)
            activeRatio = initialPressRatio
            pressPreviewTask?.cancel()
            pressPreviewTask = Task { @MainActor in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(850))
                    guard !Task.isCancelled, isPressPreviewing else { return }
                    advancePressPreview()
                }
            }
        }

        private var initialPressRatio: Double {
            guard !preview.imageOptions.isEmpty else { return 0 }
            let count = preview.imageOptions.count
            return 0.5 / Double(count)
        }

        private func advancePressPreview() {
            let count = preview.imageOptions.isEmpty ? spriteFrames.count : preview.imageOptions.count
            guard count > 0 else { return }
            let current = EntityThumbnailPreview.index(for: activeRatio ?? 0, count: count) ?? 0
            let next = (current + 1) % count
            activeRatio = (Double(next) + 0.5) / Double(count)
        }
    #endif

    private func endPressPreview() {
        guard isPressPreviewing || pressPreviewTask != nil else { return }
        let wasPreviewing = isPressPreviewing
        isPressPreviewing = false
        pressPreviewTask?.cancel()
        pressPreviewTask = nil
        activeRatio = nil
        if wasPreviewing { onPreviewHoldChanged(false) }
    }

    private func endInteractivePreview() {
        hoverIntentTask?.cancel()
        hoverIntentTask = nil
        pendingHoverRatio = nil
        activeRatio = nil
        endPressPreview()
    }

    private func adjustPreview(_ direction: AccessibilityAdjustmentDirection) {
        let count = preview.kind == .imageSequence ? preview.imageOptions.count : spriteFrames.count
        guard count > 0 else {
            if preview.spritePlaylistPath != nil {
                activeRatio = 0
            }
            return
        }

        let currentIndex = EntityThumbnailPreview.index(for: activeRatio ?? 0, count: count) ?? 0
        let nextIndex: Int
        switch direction {
        case .increment:
            nextIndex = activeRatio == nil ? 0 : min(count - 1, currentIndex + 1)
        case .decrement:
            nextIndex = activeRatio == nil ? count - 1 : max(0, currentIndex - 1)
        @unknown default:
            return
        }
        activeRatio = (Double(nextIndex) + 0.5) / Double(count)
    }

    private func loadSpriteFrames(from playlistPath: String) async {
        guard let client = environment.client else { return }
        do {
            let data = try await client.mediaData(for: playlistPath)
            guard
                let contents = String(data: data, encoding: .utf8),
                let playlistURL = client.authenticatedMediaURL(for: playlistPath)
            else {
                spriteLoadFailed = true
                return
            }
            let frames = try TrickplayPlaylist.parse(
                contents: contents,
                playlistURL: playlistURL
            ).frames
            guard !Task.isCancelled else { return }
            spriteFrames = frames
            spriteLoadFailed = frames.isEmpty
        } catch is CancellationError {
            return
        } catch {
            spriteLoadFailed = true
        }
    }

    private func authenticatedURL(for url: URL) -> URL {
        environment.client?.authenticatedMediaURL(for: url.absoluteString) ?? url
    }

    private func spriteFrameIdentity(_ frame: TrickplayPlaylist.Frame) -> String {
        "\(frame.imageURL.absoluteString)|\(frame.crop.x)|\(frame.crop.y)"
    }
}

#if DEBUG
    #Preview("Segmented Thumbnail Media") {
        PreviewShell {
            EntityThumbnailMediaView(
                item: EntityThumbnail(
                    id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
                    kind: .videoSeries,
                    title: "The Chair Company",
                    coverURL: "/preview/series.jpg",
                    hoverImages: [
                        EntityThumbnailHoverImage(
                            entityID: UUID(uuidString: "11111111-1111-1111-1111-111111111111"),
                            title: "Pilot",
                            path: "/preview/pilot.jpg"
                        ),
                        EntityThumbnailHoverImage(
                            entityID: UUID(uuidString: "22222222-2222-2222-2222-222222222222"),
                            title: "Finale",
                            path: "/preview/finale.jpg"
                        ),
                    ]
                ),
                systemImage: "rectangle.stack",
                contentMode: .fill
            )
            .aspectRatio(2.0 / 3.0, contentMode: .fit)
            .frame(width: 180)
            .prismediaCard()
            .padding()
            .background(PrismediaBackdrop())
        }
    }
#endif
