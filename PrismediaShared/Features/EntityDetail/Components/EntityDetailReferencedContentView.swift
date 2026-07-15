import SwiftUI

struct EntityDetailReferencedContentView: View {
    let presentation: EntityDetailReferencedContentPresentation
    let loader: any EntityGridLoading

    var body: some View {
        EntityGridView(
            configuration: EntityGridConfiguration(
                title: presentation.title,
                query: presentation.query,
                supportsSearch: true,
                pageSize: 48,
                minimumColumnWidth: minimumColumnWidth,
                preferencesID: presentation.preferencesID
            ),
            loader: loader,
            presentation: .embedded,
            horizontalContentPadding: 0
        ) { item, layout in
            EntityThumbnailNavigationSurface(item: item, layout: layout)
        }
        .padding(PrismediaSpacing.extraLarge)
        .entityDetailContentSurface()
        .accessibilityIdentifier("entity-detail.referenced-content")
    }

    private var minimumColumnWidth: CGFloat {
        #if os(tvOS)
            240
        #else
            150
        #endif
    }
}

#if DEBUG
    #Preview("Entity Detail Referenced Content") {
        let detail = EntityDetailPreviewFixture.detail
        let presentation = EntityDetailReferencedContentPresentation(
            detail: EntityDetail(
                id: detail.id,
                kind: .tag,
                title: "Atmospheric",
                parentEntityID: nil,
                sortOrder: nil,
                hasSourceMedia: false,
                capabilities: detail.capabilities,
                childrenByKind: [],
                relationships: []
            )
        )!

        PreviewShell {
            ScrollView {
                EntityDetailReferencedContentView(
                    presentation: presentation,
                    loader: StaticEntityGridLoader(
                        items: detail.childrenByKind.flatMap(\.entities),
                        allowsNsfwContent: true
                    )
                )
                .padding(PrismediaSpacing.extraLarge)
            }
        }
    }
#endif
