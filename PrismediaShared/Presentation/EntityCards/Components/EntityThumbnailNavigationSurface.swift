import SwiftUI

public struct EntityThumbnailNavigationSurface: View {
    @Environment(PrismediaAppRouter.self) private var router
    @Environment(\.entityMediaSequence) private var mediaSequence
    @Environment(\.entityThumbnailShowsText) private var showsThumbnailText
    @State private var preventsNavigation = false
    @State private var previewReleaseID = UUID()

    private let item: EntityThumbnail
    private let layout: EntityThumbnailLayout
    private let preferredWidth: CGFloat?
    private let previewSubtitle: String?
    private let subtitleLineLimit: Int?
    private let intent: EntityNavigationIntent
    private let onPrimaryAction: ((EntityThumbnail) -> Void)?

    public init(
        item: EntityThumbnail,
        layout: EntityThumbnailLayout = .grid,
        preferredWidth: CGFloat? = nil,
        previewSubtitle: String? = nil,
        subtitleLineLimit: Int? = 1,
        intent: EntityNavigationIntent = .detail,
        onPrimaryAction: ((EntityThumbnail) -> Void)? = nil
    ) {
        self.item = item
        self.layout = layout
        self.preferredWidth = preferredWidth
        self.previewSubtitle = previewSubtitle
        self.subtitleLineLimit = subtitleLineLimit
        self.intent = intent
        self.onPrimaryAction = onPrimaryAction
    }

    public var body: some View {
        navigationSurface
            .modifier(EntityThumbnailSurfaceWidthModifier(preferredWidth: preferredWidth))
    }

    private var navigationSurface: some View {
        ZStack(alignment: .topTrailing) {
            primaryNavigationControl

            if showsContextMenu {
                contextMenu
                    .padding(PrismediaSpacing.small)
            }
        }
    }

    @ViewBuilder
    private var primaryNavigationControl: some View {
        if separatesArtworkAndCaption {
            EntityThumbnailCardView(
                item: item,
                layout: layout,
                preferredWidth: preferredWidth,
                subtitle: previewSubtitle,
                subtitleLineLimit: subtitleLineLimit,
                onPreviewHoldChanged: previewHoldDidChange,
                onArtworkAction: openPrimaryAction,
                artworkActionHint: primaryAccessibilityHint
            )
        } else {
            Button(action: openPrimaryAction) {
                EntityThumbnailCardView(
                    item: item,
                    layout: layout,
                    preferredWidth: preferredWidth,
                    subtitle: previewSubtitle,
                    subtitleLineLimit: subtitleLineLimit,
                    onPreviewHoldChanged: previewHoldDidChange
                )
                .contentShape(Rectangle())
            }
            .prismediaEntityNavigationButtonStyle()
            .accessibilityHint(primaryAccessibilityHint)
        }
    }

    private var contextMenu: some View {
        Menu {
            Button(interaction.detailActionLabel, systemImage: "info.circle") {
                open(intent: .detail)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.callout.weight(.heavy))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(PrismediaColor.onMedia)
                .shadow(color: PrismediaColor.background.opacity(0.95), radius: 2, y: 1)
                .frame(
                    width: PrismediaLayout.minimumHitTarget,
                    height: PrismediaLayout.minimumHitTarget
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("More actions for \(item.title)")
        .accessibilityHint("Shows playback and navigation actions")
    }

    private var interaction: EntityThumbnailInteractionPolicy {
        EntityThumbnailInteractionPolicy(item: item, layout: layout)
    }

    private var primaryIntent: EntityNavigationIntent {
        intent == .detail ? interaction.primaryIntent : intent
    }

    private var primaryAccessibilityHint: String {
        intent == .detail ? interaction.primaryAccessibilityHint : "Opens \(item.title)"
    }

    private var showsContextMenu: Bool {
        intent == .detail && interaction.showsContextMenu
    }

    private var separatesArtworkAndCaption: Bool {
        #if os(tvOS)
            guard showsThumbnailText else { return false }
            switch layout {
            case .grid, .rail, .wall, .mediaOnly:
                return true
            case .list, .feed, .compact:
                return false
            }
        #else
            return false
        #endif
    }

    private func openPrimaryAction() {
        guard !preventsNavigation else { return }
        if let onPrimaryAction {
            onPrimaryAction(item)
            return
        }
        open(intent: primaryIntent)
    }

    private func open(intent: EntityNavigationIntent) {
        router.open(
            entity: item,
            previewSubtitle: previewSubtitle,
            intent: intent,
            within: item.kind == .image ? mediaSequence : nil
        )
    }

    private func previewHoldDidChange(_ isPreviewing: Bool) {
        let releaseID = UUID()
        previewReleaseID = releaseID

        guard !isPreviewing else {
            preventsNavigation = true
            return
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            guard previewReleaseID == releaseID else { return }
            preventsNavigation = false
        }
    }
}

#if DEBUG
    #Preview("Entity Thumbnail Navigation Surface") {
        PreviewShell {
            NavigationStack {
                EntityThumbnailNavigationSurface(
                    item: PrismediaPreviewData.series
                )
                .frame(width: 180)
                .padding()
            }
        }
    }

    #Preview("Direct Play Episode With Detail Menu") {
        PreviewShell {
            NavigationStack {
                EntityThumbnailNavigationSurface(
                    item: EntityThumbnail(
                        id: UUID(uuidString: "bbbbbbbb-cccc-dddd-eeee-ffffffffffff")!,
                        kind: .video,
                        title: "Episode Seven",
                        summary: "Tap the card to play or use the menu to open episode details.",
                        parentKind: .videoSeason,
                        sortOrder: 7,
                        coverURL: "/preview/video-1.jpg",
                        hasSourceMedia: true,
                        resumeSeconds: 642
                    ),
                    layout: .grid,
                    preferredWidth: 320
                )
                .padding()
            }
        }
    }
#endif
