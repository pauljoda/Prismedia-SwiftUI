import SwiftUI

extension View {
    public func prismediaEntityDestinations(
        dependencies: EntityDetailDependencies
    ) -> some View {
        navigationDestination(for: EntityLink.self) { link in
            EntityDestinationView(link: link, dependencies: dependencies)
                .id(link)
        }
    }

    public func prismediaEntityDestination(
        item: Binding<EntityLink?>,
        dependencies: EntityDetailDependencies
    ) -> some View {
        navigationDestination(item: item) { link in
            EntityDestinationView(link: link, dependencies: dependencies)
                .id(link)
        }
    }
}

#if DEBUG
    #Preview("Entity Destination Registration") {
        let detail = EntityDetailPreviewFixture.detail
        let dependencies = EntityDetailDependencies(
            detailLoader: PreviewEntityDetailLoader(detail: detail),
            mutator: nil,
            collectionItemsLoader: nil,
            readerService: nil,
            videoPlaybackService: VideoPlaybackPreviewService(),
            onEntityMutated: {}
        )

        PreviewShell(signedIn: true) {
            NavigationStack {
                NavigationLink(
                    "Open Entity",
                    value: EntityLink(entityID: detail.id, kind: detail.kind)
                )
                .prismediaEntityDestinations(dependencies: dependencies)
            }
        }
    }
#endif
