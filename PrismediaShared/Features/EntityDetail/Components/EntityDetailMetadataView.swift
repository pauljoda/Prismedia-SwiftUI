import SwiftUI

struct EntityDetailMetadataView: View {
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
    @Environment(\.artworkSecondaryText) private var artworkSecondaryText

    let items: [EntityDetailMetadataItem]

    var body: some View {
        if items.isEmpty {
            ContentUnavailableView(
                "Metadata",
                systemImage: "info.circle",
                description: Text("No metadata is available yet.")
            )
            .frame(maxWidth: .infinity)
        } else {
            EntityDetailPlatformMetadataGrid(items: items) { item in
                metadataItem(item)
            }
        }
    }

    @ViewBuilder
    private func metadataItem(_ item: EntityDetailMetadataItem) -> some View {
        #if os(tvOS)
            metadataItemContent(item)
        #else
            if let url = item.url {
                Link(destination: url) {
                    metadataItemContent(item)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens in your default browser")
            } else {
                metadataItemContent(item)
            }
        #endif
    }

    private func metadataItemContent(_ item: EntityDetailMetadataItem) -> some View {
        HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
            Image(systemName: item.systemImage)
                .frame(width: 20)
                .foregroundStyle(artworkPrimaryAccent)

            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Text(item.label)
                    .font(.caption)
                    .foregroundStyle(artworkSecondaryText)
                Text(item.value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PrismediaColor.textPrimary)
                    .lineLimit(3)
                if item.url != nil {
                    Label("Open Link", systemImage: "arrow.up.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(artworkPrimaryAccent)
                }
            }
        }
        .padding(.vertical, PrismediaSpacing.medium)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            Divider()
                .overlay(PrismediaColor.borderSubtle)
        }
    }
}

#if DEBUG
    #Preview("Entity Detail Metadata") {
        EntityDetailMetadataView(
            items: [
                .init(label: "Rating", value: "4 / 5", systemImage: "star.fill"),
                .init(label: "Favorite", value: "Yes", systemImage: "heart.fill"),
                .init(label: "Resolution", value: "3840 × 2160", systemImage: "rectangle"),
            ]
        )
        .padding()
    }
#endif
