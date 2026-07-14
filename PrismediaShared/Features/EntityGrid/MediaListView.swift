import SwiftUI

/// Compatibility wrapper for callers that still describe a list with separate
/// title/query arguments. New feature surfaces should construct EntityGridView
/// with an EntityGridConfiguration and provide their own navigation link label.
public struct MediaListView: View {
    @Environment(PrismediaAppEnvironment.self) private var environment

    private let configuration: EntityGridConfiguration
    private let loaderOverride: (any EntityGridLoading)?

    public init(title: String, query: EntityListQuery, supportsSearch: Bool = false) {
        configuration = EntityGridConfiguration(
            title: title,
            query: query,
            supportsSearch: supportsSearch
        )
        loaderOverride = nil
    }

    init(title: String, query: EntityListQuery, previewItems: [EntityThumbnail]) {
        configuration = EntityGridConfiguration(title: title, query: query)
        loaderOverride = StaticEntityGridLoader(items: previewItems)
    }

    public var body: some View {
        NavigationStack {
            if let loaderOverride {
                entityGrid(loader: loaderOverride)
            } else if let client = environment.client {
                entityGrid(loader: PrismediaEntityGridLoader(client: client))
            } else {
                PrismediaLoadingView("Loading library…")
            }
        }
    }

    private func entityGrid(loader: any EntityGridLoading) -> some View {
        EntityGridView(
            configuration: configuration,
            loader: loader
        ) { item, layout in
            EntityThumbnailNavigationSurface(item: item, layout: layout)
        }
    }
}

#if DEBUG

    #Preview("Videos Grid") {
        PreviewShell(signedIn: true) {
            MediaListView(
                title: "Videos",
                query: EntityListQuery(kind: .video),
                previewItems: PrismediaPreviewData.videos
            )
        }
        #if os(tvOS)
            .environment(TVTabFocusCoordinator())
        #endif
    }
#endif
