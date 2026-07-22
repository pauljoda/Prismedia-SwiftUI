#if os(macOS)
    import SwiftUI

    struct EntityDetailPlatformMetadataGrid<Content: View>: View {
        let items: [EntityDetailMetadataItem]
        @ViewBuilder let content: (EntityDetailMetadataItem) -> Content

        var body: some View {
            LazyVGrid(
                columns: [
                    GridItem(
                        .adaptive(minimum: 220),
                        spacing: PrismediaSpacing.extraLarge,
                        alignment: .topLeading
                    )
                ],
                alignment: .leading,
                spacing: 0
            ) {
                ForEach(items) { item in
                    content(item)
                }
            }
        }
    }

    #Preview("Mac Entity Detail Metadata Grid") {
        EntityDetailPlatformMetadataGrid(
            items: [.init(label: "Rating", value: "4 / 5", systemImage: "star.fill")]
        ) { item in
            Text("\(item.label): \(item.value)")
        }
        .padding()
    }
#endif
