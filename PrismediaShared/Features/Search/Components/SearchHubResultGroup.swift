import SwiftUI

struct SearchHubResultGroup: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
                Label(
                    section.title,
                    systemImage: SearchHubKindCatalog.systemImage(for: section.kind)
                )
                .font(.title2.bold())
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)

                Spacer()

                Text(section.items.count, format: .number)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("\(section.items.count) loaded results")
            }

            LazyVGrid(columns: resultColumns, spacing: 0) {
                ForEach(visibleItems) { item in
                    entityRow(item)
                }
            }

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

    private var resultColumns: [GridItem] {
        if usesRegularLayout && !dynamicTypeSize.isAccessibilitySize {
            return [
                GridItem(.flexible(), spacing: PrismediaSpacing.large),
                GridItem(.flexible(), spacing: PrismediaSpacing.large),
            ]
        }
        return [GridItem(.flexible())]
    }

    private func entityRow(_ item: EntityThumbnail) -> some View {
        NavigationLink(value: EntityLink(thumbnail: item)) {
            HStack(spacing: PrismediaSpacing.medium) {
                RemotePosterImage(
                    path: item.bestCoverPath,
                    fallbackSeed: item.title,
                    systemImage: SearchHubKindCatalog.systemImage(for: item.kind)
                )
                .frame(width: usesRegularLayout ? 48 : 56, height: usesRegularLayout ? 48 : 56)
                .clipShape(
                    PrismediaStableRoundedRectangle(cornerRadius: PrismediaRadius.control)
                )
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                    HStack(spacing: PrismediaSpacing.small) {
                        Text(item.title)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        if item.id == topResultID {
                            Text("Top")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(PrismediaColor.accent)
                                .accessibilityLabel("Top result")
                        }
                    }

                    Text(metadataLine(for: item))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: PrismediaSpacing.small)

                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, minHeight: usesRegularLayout ? 56 : 68, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.title), \(metadataLine(for: item))")
        .accessibilityHint(item.id == topResultID ? "Top result. Opens details" : "Opens details")
        .accessibilityIdentifier("shell.search.result.\(item.id.uuidString)")
    }

    private func metadataLine(for item: EntityThumbnail) -> String {
        let firstMetadata = item.meta.first?.label
        return [item.kind.displayLabel, firstMetadata]
            .compactMap { $0 }
            .joined(separator: " · ")
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
