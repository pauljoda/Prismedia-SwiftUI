#if os(iOS)
import SwiftUI

struct EntityDetailPlatformLoadingView: View {
    let link: EntityLink

    var body: some View {
        if link.kind == .audioLibrary, let preview = link.thumbnailPreview {
            MusicAlbumLoadingView(preview: preview)
                .accessibilityIdentifier("entity-detail.loading")
        } else {
            PrismediaLoadingView("Loading details…")
                .accessibilityIdentifier("entity-detail.loading")
        }
    }
}

#Preview("iOS Entity Detail Loading") {
    EntityDetailPlatformLoadingView(
        link: EntityLink(entityID: EntityDetailPreviewFixture.detail.id, kind: .movie)
    )
}
#endif
