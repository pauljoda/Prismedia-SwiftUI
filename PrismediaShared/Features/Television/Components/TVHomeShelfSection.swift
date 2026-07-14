import SwiftUI

#if os(tvOS)

    struct TVHomeShelfSection: View {
        let shelf: TVHomeShelf
        let items: [EntityThumbnail]
        let failed: Bool
        let onReload: () -> Void
        let onSelectTab: (String) -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraLarge) {
                header
                if failed {
                    PrismediaButton("Try Again", action: onReload)
                        .padding(.horizontal, 72)
                } else {
                    itemRail
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("tv.home.shelf.\(shelf.id)")
        }

        private var header: some View {
            HStack {
                Label(shelf.title, systemImage: shelf.systemImage)
                    .font(.title2.bold())
                Spacer()
                if let destinationTabID = shelf.destinationTabID {
                    PrismediaButton("See All") { onSelectTab(destinationTabID) }
                        .accessibilityIdentifier("tv.home.shelf.\(shelf.id).see-all")
                }
            }
            .padding(.horizontal, 72)
        }

        private var itemRail: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: PrismediaSpacing.section) {
                    ForEach(items) { item in
                        EntityThumbnailNavigationSurface(
                            item: item,
                            layout: .rail,
                            preferredWidth: item.thumbnailPresentationKind.prefersWideThumbnail
                                ? 360
                                : 250
                        )
                    }
                }
                .padding(.horizontal, 72)
                .padding(.vertical, PrismediaSpacing.medium)
            }
            .frame(height: 420)
        }
    }
#endif
#if os(tvOS) && DEBUG
    #Preview("TV Home Shelf · Content · Accessibility Type") {
        PreviewShell {
            NavigationStack {
                if let shelf = TVAppCatalog.homeShelves.first(where: { $0.id == "movies" }) {
                    TVHomeShelfSection(
                        shelf: shelf,
                        items: [TVHomePreviewLoader().item, PrismediaPreviewData.series],
                        failed: false,
                        onReload: {},
                        onSelectTab: { _ in }
                    )
                }
            }
        }
        .environment(\.dynamicTypeSize, .accessibility3)
    }

    #Preview("TV Home Shelf · Failure") {
        PreviewShell {
            if let shelf = TVAppCatalog.homeShelves.first(where: { $0.id == "movies" }) {
                TVHomeShelfSection(
                    shelf: shelf,
                    items: [],
                    failed: true,
                    onReload: {},
                    onSelectTab: { _ in }
                )
            }
        }
    }
#endif
