import SwiftUI

struct DashboardShelfView: View {
    let title: String
    let systemImage: String
    let colorRole: DashboardSectionColorRole
    let items: [EntityThumbnail]
    let onSelect: (() -> Void)?

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                DashboardSectionHeader(
                    title: title,
                    systemImage: systemImage,
                    colorRole: colorRole,
                    onSelect: onSelect
                )
                .padding(.horizontal, PrismediaSpacing.large)

                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: PrismediaSpacing.small) {
                        ForEach(items) { item in
                            EntityThumbnailNavigationSurface(
                                item: item,
                                layout: .rail,
                                preferredWidth: railCardWidth(for: item)
                            )
                        }
                    }
                    .padding(.horizontal, PrismediaSpacing.large)
                    .padding(.bottom, PrismediaSpacing.extraSmall)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var railCardHeight: Double {
        260 / EntityThumbnailCardPresentation.extendedLandscapeAspectRatio
    }

    private func railCardWidth(for item: EntityThumbnail) -> CGFloat {
        CGFloat(
            EntityThumbnailCardPresentation(item: item, layout: .rail)
                .width(forCardHeight: railCardHeight)
        )
    }
}

#if DEBUG
    #Preview("Dashboard Shelf · Consistent Heights") {
        PreviewShell(signedIn: true) {
            DashboardShelfView(
                title: "Recently Added",
                systemImage: "movieclapper",
                colorRole: .movie,
                items: [
                    PrismediaPreviewData.videos[0],
                    PrismediaPreviewData.series,
                    PrismediaPreviewData.book,
                    PrismediaPreviewData.person,
                ],
                onSelect: {}
            )
            .padding(.vertical)
        }
    }
#endif
