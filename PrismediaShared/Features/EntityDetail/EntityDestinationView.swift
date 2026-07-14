import SwiftUI

public struct EntityDestinationView: View {
    @State private var imageViewerSession: EntityImageViewerSession?

    private let link: EntityLink
    private let dependencies: EntityDetailDependencies

    public init(
        link: EntityLink,
        dependencies: EntityDetailDependencies
    ) {
        self.link = link
        self.dependencies = dependencies
        _imageViewerSession = State(
            initialValue: EntityImageViewerRouteSessionFactory.make(
                for: link,
                sequenceLoader: dependencies.mediaSequenceLoader
            )
        )
    }

    public var body: some View {
        EntityDetailView(
            link: link,
            dependencies: dependencies,
            imageViewerSession: imageViewerSession
        )
    }
}

#if DEBUG
    #Preview("Entity Destination") {
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
                EntityDestinationView(
                    link: EntityLink(entityID: detail.id, kind: detail.kind),
                    dependencies: dependencies
                )
            }
        }
    }
#endif
