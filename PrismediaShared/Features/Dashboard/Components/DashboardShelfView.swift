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
                                preferredWidth: item.thumbnailPresentationKind.prefersWideThumbnail
                                    ? 260
                                    : 124
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
}

#if DEBUG
    #Preview("Dashboard Shelf · Movies") {
        PreviewShell(signedIn: true) {
            DashboardShelfView(
                title: "Movies",
                systemImage: "movieclapper",
                colorRole: .movie,
                items: PrismediaPreviewData.videos,
                onSelect: {}
            )
            .padding(.vertical)
        }
    }
#endif
