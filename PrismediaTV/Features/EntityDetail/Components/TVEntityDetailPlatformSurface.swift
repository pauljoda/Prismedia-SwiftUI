#if os(tvOS)
import SwiftUI

struct EntityDetailPlatformSurface<StandardContent: View, BackdropContent: View>: View {
    let detail: EntityDetail
    let presentation: EntityDetailPresentation
    let previewPath: String?
    @Binding var palette: ArtworkPalette?
    @ViewBuilder let standardContent: () -> StandardContent
    @ViewBuilder let backdropContent: () -> BackdropContent

    var body: some View {
        TVEntityDetailBackdropSurface(
            heroPath: presentation.heroPath,
            posterPath: presentation.posterPath,
            previewPath: previewPath,
            fallbackSeed: detail.title,
            systemImage: presentation.systemImage,
            palette: $palette,
            content: backdropContent
        )
    }
}

#if DEBUG
    #Preview("TV Entity Detail Surface") {
        @Previewable @State var palette: ArtworkPalette?
        let detail = EntityDetailPreviewFixture.detail
        EntityDetailPlatformSurface(
            detail: detail,
            presentation: EntityDetailPresentation(detail: detail),
            previewPath: nil,
            palette: $palette,
            standardContent: { Text(detail.title).padding(72) },
            backdropContent: { Text(detail.title).padding(72) }
        )
    }
#endif
#endif
