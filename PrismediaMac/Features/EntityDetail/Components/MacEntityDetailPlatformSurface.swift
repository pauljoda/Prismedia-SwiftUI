#if os(macOS)
import SwiftUI

struct EntityDetailPlatformSurface<StandardContent: View, BackdropContent: View>: View {
    let detail: EntityDetail
    let presentation: EntityDetailPresentation
    let previewPath: String?
    @Binding var palette: ArtworkPalette?
    @ViewBuilder let standardContent: () -> StandardContent
    @ViewBuilder let backdropContent: () -> BackdropContent

    var body: some View {
        standardContent()
    }
}

#if DEBUG
    #Preview("Mac Entity Detail Surface") {
        @Previewable @State var palette: ArtworkPalette?
        let detail = EntityDetailPreviewFixture.detail
        EntityDetailPlatformSurface(
            detail: detail,
            presentation: EntityDetailPresentation(detail: detail),
            previewPath: nil,
            palette: $palette,
            standardContent: { Text(detail.title).padding() },
            backdropContent: { Color.clear }
        )
    }
#endif
#endif
