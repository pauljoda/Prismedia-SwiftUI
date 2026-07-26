#if os(macOS)
import SwiftUI

struct EntityDetailPlatformLoadingView: View {
    let link: EntityLink

    var body: some View {
        if usesAlbumLoadingSurface, let preview = link.thumbnailPreview {
            MusicAlbumLoadingView(preview: preview)
                .accessibilityIdentifier("entity-detail.loading")
        } else {
            PrismediaLoadingView("Loading details…")
                .accessibilityIdentifier("entity-detail.loading")
        }
    }

    private var usesAlbumLoadingSurface: Bool {
        let style = EntityDestinationPolicy.style(
            for: link.kind,
            on: .current,
            intent: link.intent
        )
        return style == .nativeAlbum || style == .nativeAudioCollection
    }
}

#if DEBUG
    #Preview("Mac Entity Detail Loading") {
        EntityDetailPlatformLoadingView(
            link: EntityLink(entityID: EntityDetailPreviewFixture.detail.id, kind: .movie)
        )
    }
#endif
#endif
