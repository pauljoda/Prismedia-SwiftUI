#if os(macOS)
    import SwiftUI

    struct EntityDetailPlatformOverviewView<DefaultOverview: View>: View {
        let presentation: EntityDetailPresentation
        let previewPath: String?
        let showsArtwork: Bool
        @ViewBuilder let defaultOverview: () -> DefaultOverview

        var body: some View {
            defaultOverview()
        }
    }

    #if DEBUG
        #Preview("Mac Entity Detail Overview") {
            EntityDetailPlatformOverviewView(
                presentation: EntityDetailPresentation(detail: EntityDetailPreviewFixture.detail),
                previewPath: nil,
                showsArtwork: true
            ) {
                Text("Overview")
            }
        }
    #endif
#endif
