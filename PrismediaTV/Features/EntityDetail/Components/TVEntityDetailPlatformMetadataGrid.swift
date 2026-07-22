#if os(tvOS)
    import SwiftUI

    struct EntityDetailPlatformMetadataGrid<Content: View>: View {
        let items: [EntityDetailMetadataItem]
        @ViewBuilder let content: (EntityDetailMetadataItem) -> Content

        var body: some View {
            LazyVGrid(
                columns: [
                    GridItem(
                        .adaptive(minimum: 360),
                        spacing: PrismediaSpacing.extraExtraLarge,
                        alignment: .topLeading
                    )
                ],
                alignment: .leading,
                spacing: PrismediaSpacing.small
            ) {
                ForEach(items) { item in
                    content(item)
                }
            }
        }
    }

    #Preview("TV Entity Detail Metadata Rows") {
        EntityDetailPlatformMetadataGrid(
            items: [
                .init(label: "Rating", value: "4 / 5", systemImage: "star.fill"),
                .init(label: "Favorite", value: "Yes", systemImage: "heart.fill"),
                .init(label: "Organized", value: "Yes", systemImage: "checkmark.circle.fill"),
            ]
        ) { item in
            Text("\(item.label): \(item.value)")
        }
        .padding(72)
        .frame(width: 1_920)
    }
#endif
