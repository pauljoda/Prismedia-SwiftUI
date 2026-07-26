import SwiftUI

struct SearchHubResultGroup: View {
    let section: SearchHubResultSection
    let isExpanded: Bool
    let usesRegularLayout: Bool
    let topResultID: UUID?
    let onToggleExpansion: () -> Void

    private var collapsedLimit: Int {
        usesRegularLayout ? 8 : 5
    }

    private var visibleItems: [EntityThumbnail] {
        isExpanded ? section.items : Array(section.items.prefix(collapsedLimit))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            HStack {
                Label {
                    Text(section.title)
                } icon: {
                    Image(systemName: SearchHubKindCatalog.systemImage(for: section.kind))
                        .foregroundStyle(PrismediaColor.entityAccent(for: section.kind))
                }
                .font(.title2.bold())
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)

                Spacer()

                Text(section.items.count, format: .number)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("\(section.items.count) loaded results")
            }

            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: PrismediaSpacing.small) {
                    ForEach(visibleItems) { item in
                        entityCard(item)
                    }
                }
                .padding(.bottom, PrismediaSpacing.extraSmall)
            }
            .scrollIndicators(.hidden)

            if section.items.count > collapsedLimit {
                Button {
                    onToggleExpansion()
                } label: {
                    Label(
                        isExpanded
                            ? "Show Fewer"
                            : "Show \(section.items.count - collapsedLimit) More",
                        systemImage: isExpanded ? "chevron.up" : "chevron.down"
                    )
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("shell.search.expand.\(section.kind.rawValue)")
            }
        }
        .accessibilityIdentifier("shell.search.section.\(section.kind.rawValue)")
    }

    private var railArtworkHeight: CGFloat {
        CGFloat(260 / EntityThumbnailCardPresentation.extendedLandscapeAspectRatio)
    }

    private func entityCard(_ item: EntityThumbnail) -> some View {
        EntityThumbnailNavigationSurface(
            item: item,
            layout: .rail,
            preferredWidth: railCardWidth(for: item)
        )
        .accessibilityHint(item.id == topResultID ? "Top result. Opens details" : "Opens details")
        .accessibilityIdentifier("shell.search.result.\(item.id.uuidString)")
    }

    private func railCardWidth(for item: EntityThumbnail) -> CGFloat {
        CGFloat(
            EntityThumbnailCardPresentation(item: item, layout: .rail)
                .width(forCardHeight: Double(railArtworkHeight))
        )
    }
}

#if DEBUG
    #Preview("Search Result Group") {
        NavigationStack {
            SearchHubResultGroup(
                section: SearchHubResultSection(
                    kind: .video,
                    items: Array(PrismediaPreviewData.allEntities.prefix(6))
                ),
                isExpanded: false,
                usesRegularLayout: false,
                topResultID: PrismediaPreviewData.allEntities.first?.id,
                onToggleExpansion: {}
            )
            .padding()
            .prismediaScreenBackground()
        }
    }
#endif
