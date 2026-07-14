import SwiftUI

struct GalleryDetailChildGroupsView: View {
    @Environment(PrismediaAppRouter.self) private var router
    @Environment(PrismediaAppEnvironment.self) private var environment
    @Environment(\.artworkSecondaryText) private var artworkSecondaryText
    @State private var subGalleriesExpanded = true

    private let presentation: GalleryChildGroupsPresentation
    private let horizontalPadding: CGFloat
    private let dependencies: EntityDetailDependencies

    init(
        galleryID: UUID,
        groups: [EntityGroup],
        horizontalPadding: CGFloat,
        dependencies: EntityDetailDependencies
    ) {
        presentation = GalleryChildGroupsPresentation(galleryID: galleryID, groups: groups)
        self.horizontalPadding = horizontalPadding
        self.dependencies = dependencies
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
            if !presentation.subGalleries.isEmpty {
                subGalleriesSection
            }

            if !presentation.images.isEmpty {
                imageGrid
            }

            EntityDetailChildGroupsView(
                groups: presentation.remainingGroups,
                horizontalPadding: horizontalPadding
            )

            if presentation.isEmpty {
                ContentUnavailableView(
                    "No Gallery Content",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("Images and sub-galleries will appear here when they’re added.")
                )
                .frame(maxWidth: .infinity, minHeight: 180)
                .padding(.horizontal, horizontalPadding)
            }
        }
        .accessibilityIdentifier("entity-detail.gallery-children")
    }

    @ViewBuilder
    private var subGalleriesSection: some View {
        #if os(tvOS)
            VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                subGalleriesLabel
                subGalleriesGrid
            }
            .padding(.horizontal, horizontalPadding)
            .accessibilityIdentifier("entity-detail.sub-galleries")
            .accessibilityValue("Expanded")
        #else
            DisclosureGroup(isExpanded: $subGalleriesExpanded) {
                subGalleriesGrid
                    .padding(.top, PrismediaSpacing.large)
            } label: {
                subGalleriesLabel
            }
            .padding(.horizontal, horizontalPadding)
            .accessibilityIdentifier("entity-detail.sub-galleries")
            .accessibilityValue(subGalleriesExpanded ? "Expanded" : "Collapsed")
        #endif
    }

    private var subGalleriesLabel: some View {
        HStack(spacing: PrismediaSpacing.small) {
            Label("Sub Galleries", systemImage: "square.stack.3d.up")
                .font(.title3.bold())
                .foregroundStyle(PrismediaColor.textPrimary)

            Text(String(presentation.subGalleries.count))
                .font(.caption.monospacedDigit())
                .foregroundStyle(artworkSecondaryText)
        }
        .accessibilityAddTraits(.isHeader)
    }

    private var subGalleriesGrid: some View {
        EntityThumbnailGrid(
            items: presentation.subGalleries,
            minimumColumnWidth: minimumColumnWidth
        ) { item in
            EntityThumbnailNavigationSurface(item: item)
                .accessibilityIdentifier("entity-detail.sub-gallery.\(item.id.uuidString)")
        }
    }

    private var imageGrid: some View {
        EntityGridView(
            configuration: presentation.imageGridConfiguration,
            loader: StaticEntityGridLoader(
                items: presentation.images,
                allowsNsfwContent: environment.allowsNsfwContent
            ),
            presentation: .embedded,
            horizontalContentPadding: horizontalPadding,
            feedMediaDependencies: EntityMediaFeedDependencies(
                detailLoader: dependencies.detailLoader,
                sourceLoader: dependencies.imageSourceLoader,
                videoAspectRatioLoader: dependencies.imageVideoAspectRatioLoader
            ),
            onOpenFeedItem: openImage,
            itemContent: { item, layout in
                EntityThumbnailNavigationSurface(item: item, layout: layout)
            }
        )
        .accessibilityIdentifier("entity-detail.gallery-images")
    }

    private func openImage(_ item: EntityThumbnail, _ sequence: EntityMediaSequence) {
        router.open(entity: item, within: sequence)
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
    #Preview("Gallery Child Groups") {
        let gallery = EntityThumbnail(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            kind: .gallery,
            title: "Portraits"
        )
        let image = EntityThumbnail(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            kind: .image,
            title: "Window Light",
            coverURL: "/assets/mock-fixtures/still.png"
        )
        let dependencies = EntityDetailDependencies(
            detailLoader: PreviewEntityDetailLoader(detail: EntityDetailPreviewFixture.detail),
            mutator: nil,
            collectionItemsLoader: nil,
            readerService: nil,
            videoPlaybackService: nil,
            onEntityMutated: {}
        )

        PreviewShell(signedIn: true) {
            NavigationStack {
                ScrollView {
                    GalleryDetailChildGroupsView(
                        galleryID: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
                        groups: [
                            EntityGroup(kind: .image, label: "Images", entities: [image], code: "images"),
                            EntityGroup(
                                kind: .gallery,
                                label: "Sub Galleries",
                                entities: [gallery],
                                code: "galleries"
                            ),
                        ],
                        horizontalPadding: PrismediaSpacing.extraLarge,
                        dependencies: dependencies
                    )
                }
            }
        }
    }
#endif
