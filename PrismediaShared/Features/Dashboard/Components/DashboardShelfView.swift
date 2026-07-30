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

                EntityThumbnailRail(
                    items: items,
                    maximumItemCount: DashboardCatalog.itemLimit,
                    contentInsets: EdgeInsets(
                        top: 0,
                        leading: PrismediaSpacing.large,
                        bottom: PrismediaSpacing.extraSmall,
                        trailing: PrismediaSpacing.large
                    )
                ) { item, width in
                    EntityThumbnailNavigationSurface(
                        item: item,
                        layout: .rail,
                        preferredWidth: width
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#if DEBUG
    #Preview("Dashboard Shelf · Consistent Heights") {
        PreviewShell(signedIn: true) {
            DashboardShelfView(
                title: "Recently Added",
                systemImage: "movieclapper",
                colorRole: .entity(.movie),
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
