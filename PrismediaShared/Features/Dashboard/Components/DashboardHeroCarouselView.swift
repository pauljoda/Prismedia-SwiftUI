import SwiftUI

struct DashboardHeroCarouselView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var artworkPalette: ArtworkPalette?
    @State private var selectedItemID: UUID?
    @State private var sceneIndex = 0
    @State private var trickplayFramesByItem: [UUID: [TrickplayPlaylist.Frame]] = [:]

    let items: [EntityThumbnail]
    let viewportWidth: CGFloat
    let topSafeAreaHeight: CGFloat
    let trickplayLoader: any TrickplayFrameLoading
    let allowsAutomaticAdvance: Bool
    let onNavigate: (EntityLink) -> Void

    init(
        items: [EntityThumbnail],
        viewportWidth: CGFloat,
        topSafeAreaHeight: CGFloat = 0,
        trickplayLoader: any TrickplayFrameLoading,
        allowsAutomaticAdvance: Bool = true,
        onNavigate: @escaping (EntityLink) -> Void
    ) {
        self.items = items
        self.viewportWidth = viewportWidth
        self.topSafeAreaHeight = topSafeAreaHeight
        self.trickplayLoader = trickplayLoader
        self.allowsAutomaticAdvance = allowsAutomaticAdvance
        self.onNavigate = onNavigate
    }

    var body: some View {
        if !presentations.isEmpty {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(Array(presentations.enumerated()), id: \.element.id) {
                        index,
                        presentation in
                        DashboardHeroPageView(
                            presentation: presentation,
                            sceneIndex: sceneIndex(for: presentation),
                            trickplayFrames: trickplayFramesForPage(
                                presentation
                            ),
                            viewportWidth: viewportWidth,
                            topSafeAreaHeight: topSafeAreaHeight,
                            reservesProgressIndicatorSpace: showsProgressIndicator,
                            onNavigate: onNavigate
                        )
                        .frame(width: viewportWidth)
                        .id(presentation.id)
                        .accessibilityHidden(index != selectedIndex)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, 0, for: .scrollContent)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $selectedItemID)
            .scrollDisabled(presentations.count < 2)
            .frame(width: viewportWidth)
            .clipped()
            .overlay(alignment: .bottomLeading) {
                if showsProgressIndicator {
                    DashboardHeroProgressIndicator(
                        presentations: presentations,
                        sceneCounts: sceneCounts,
                        position: position,
                        accent: resolvedAccent,
                        onSelect: select
                    )
                    .padding(.horizontal, PrismediaSpacing.large)
                    .padding(.bottom, PrismediaSpacing.small)
                    .frame(
                        width: min(viewportWidth, PrismediaLayout.readableContentWidth),
                        alignment: .leading
                    )
                }
            }
            .prismediaArtworkPalette(
                for: selectedPresentation?.item.bestCoverPath,
                palette: $artworkPalette
            )
            .onChange(of: selectedItemID) { oldValue, newValue in
                guard oldValue != newValue, newValue != nil else { return }
                sceneIndex = 0
            }
            .task(id: trickplayTaskID) {
                guard let presentation = selectedPresentation else { return }
                await loadTrickplay(for: presentation)
            }
            .task(id: motionTaskID) {
                normalizePosition()
                guard !reduceMotion, allowsAutomaticAdvance else { return }

                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(4))
                    guard !Task.isCancelled else { return }
                    let next = DashboardHeroAdvancePolicy.next(
                        from: position,
                        sceneCounts: sceneCounts,
                        reduceMotion: reduceMotion
                    )
                    withAnimation(.easeInOut(duration: 0.82)) {
                        selectedItemID = presentations[next.itemIndex].id
                        sceneIndex = next.sceneIndex
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Featured media")
            .accessibilityValue("Featured \(selectedIndex + 1) of \(presentations.count)")
            .accessibilityAdjustableAction(adjustPage)
            .accessibilityIdentifier("dashboard.hero")
        }
    }

    private var presentations: [DashboardHeroPresentation] {
        items.map(DashboardHeroPresentation.init)
    }

    private var selectedPresentation: DashboardHeroPresentation? {
        guard !presentations.isEmpty else { return nil }
        return presentations[selectedIndex]
    }

    private var selectedIndex: Int {
        guard let selectedItemID,
            let index = presentations.firstIndex(where: { $0.id == selectedItemID })
        else {
            return 0
        }
        return index
    }

    private var position: DashboardHeroPosition {
        DashboardHeroPosition(itemIndex: selectedIndex, sceneIndex: sceneIndex)
    }

    private var resolvedAccent: Color {
        artworkPalette?.primary.color ?? PrismediaColor.accent
    }

    private var sceneCounts: [Int] {
        guard !reduceMotion else { return Array(repeating: 1, count: presentations.count) }
        return presentations.map(effectiveSceneCount)
    }

    private var selectedSceneCount: Int {
        guard sceneCounts.indices.contains(selectedIndex) else { return 1 }
        return max(sceneCounts[selectedIndex], 1)
    }

    private var showsProgressIndicator: Bool {
        presentations.count > 1 || selectedSceneCount > 1
    }

    private var motionTaskID: String {
        let counts = sceneCounts.map(String.init).joined(separator: ",")
        return items.map(\.id.uuidString).joined(separator: "|")
            + "|selected:\(selectedItemID?.uuidString ?? "none")"
            + "|scenes:\(counts)|reduce-motion:\(reduceMotion)"
    }

    private var trickplayTaskID: String {
        let path = selectedPresentation?.trickplayPlaylistPath ?? "none"
        return "\(selectedPresentation?.id.uuidString ?? "none")|\(path)|reduce-motion:\(reduceMotion)"
    }

    private func normalizePosition() {
        guard !presentations.isEmpty else {
            selectedItemID = nil
            sceneIndex = 0
            return
        }
        if selectedItemID == nil || !presentations.contains(where: { $0.id == selectedItemID }) {
            selectedItemID = presentations[0].id
            sceneIndex = 0
        }
        if reduceMotion || sceneIndex >= effectiveSceneCount(for: presentations[selectedIndex]) {
            sceneIndex = 0
        }
    }

    private func select(_ itemID: UUID) {
        guard presentations.contains(where: { $0.id == itemID }) else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.32)) {
            selectedItemID = itemID
            sceneIndex = 0
        }
    }

    private func adjustPage(_ direction: AccessibilityAdjustmentDirection) {
        let targetIndex: Int
        switch direction {
        case .increment:
            targetIndex = DashboardHeroPagingPolicy.nextIndex(
                from: selectedIndex,
                itemCount: presentations.count
            )
        case .decrement:
            targetIndex = DashboardHeroPagingPolicy.previousIndex(
                from: selectedIndex,
                itemCount: presentations.count
            )
        @unknown default:
            return
        }
        guard targetIndex != selectedIndex else { return }
        select(presentations[targetIndex].id)
    }

    private func sceneIndex(for presentation: DashboardHeroPresentation) -> Int {
        presentation.id == selectedItemID ? sceneIndex : 0
    }

    private func trickplayFramesForPage(
        _ presentation: DashboardHeroPresentation
    ) -> [TrickplayPlaylist.Frame] {
        presentation.id == selectedItemID ? trickplayFrames(for: presentation) : []
    }

    private func trickplayFrames(
        for presentation: DashboardHeroPresentation
    ) -> [TrickplayPlaylist.Frame] {
        trickplayFramesByItem[presentation.id] ?? []
    }

    private func effectiveSceneCount(for presentation: DashboardHeroPresentation) -> Int {
        let frames = trickplayFrames(for: presentation)
        return frames.isEmpty ? presentation.sceneCount : frames.count + 1
    }

    @MainActor
    private func loadTrickplay(for presentation: DashboardHeroPresentation) async {
        guard
            !reduceMotion,
            trickplayFramesByItem[presentation.id] == nil,
            let playlistPath = presentation.trickplayPlaylistPath
        else {
            return
        }

        let loadedFrames = await trickplayLoader.loadFrames(playlistPath: playlistPath)
        guard !Task.isCancelled else { return }
        trickplayFramesByItem[presentation.id] = DashboardTrickplayFrameSampler.sample(
            loadedFrames,
            limit: 5
        )
        if selectedItemID == presentation.id,
            sceneIndex >= effectiveSceneCount(for: presentation)
        {
            sceneIndex = 0
        }
    }
}

#if DEBUG
    #Preview("Dashboard Hero Carousel · Content") {
        PreviewShell(signedIn: true) {
            ScrollView {
                DashboardHeroCarouselView(
                    items: PrismediaPreviewData.videos,
                    viewportWidth: 720,
                    trickplayLoader: DashboardHeroPreviewTrickplayLoader(),
                    allowsAutomaticAdvance: true,
                    onNavigate: { _ in }
                )
            }
        }
    }

    #Preview("Dashboard Hero Carousel · Accessibility Type") {
        PreviewShell(signedIn: true) {
            DashboardHeroCarouselView(
                items: [PrismediaPreviewData.videos[0]],
                viewportWidth: 320,
                trickplayLoader: DashboardHeroPreviewTrickplayLoader(),
                allowsAutomaticAdvance: true,
                onNavigate: { _ in }
            )
        }
        .environment(\.dynamicTypeSize, .accessibility2)
    }
#endif
