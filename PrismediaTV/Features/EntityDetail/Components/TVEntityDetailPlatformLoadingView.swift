#if os(tvOS)
import SwiftUI

struct EntityDetailPlatformLoadingView: View {
    let link: EntityLink

    var body: some View {
        PrismediaLoadingView("Loading details…")
            .accessibilityIdentifier("entity-detail.loading")
    }
}

#Preview("TV Entity Detail Loading") {
    EntityDetailPlatformLoadingView(
        link: EntityLink(entityID: EntityDetailPreviewFixture.detail.id, kind: .movie)
    )
}
#endif
