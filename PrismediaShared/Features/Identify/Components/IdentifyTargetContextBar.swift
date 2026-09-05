import SwiftUI

#if os(iOS) || os(macOS)
    /// Expandable context showing which library item the current
    /// search or proposal applies to, mirroring the web target preview.
    struct IdentifyTargetContextBar: View {
        let item: AdministrativeIdentifyQueueItem
        let thumbnail: EntityThumbnail?
        let isLoading: Bool
        @State private var isExpanded = false

        init(
            item: AdministrativeIdentifyQueueItem,
            thumbnail: EntityThumbnail? = nil,
            isLoading: Bool = false,
            startsExpanded: Bool = false
        ) {
            self.item = item
            self.thumbnail = thumbnail
            self.isLoading = isLoading
            _isExpanded = State(initialValue: startsExpanded)
        }

        var body: some View {
            DisclosureGroup(isExpanded: $isExpanded) {
                Group {
                    if thumbnail == nil, isLoading {
                        HStack(spacing: PrismediaSpacing.small) {
                            ProgressView()
                            Text("Loading item preview…")
                        }
                        .frame(maxWidth: .infinity, minHeight: 88)
                        .foregroundStyle(PrismediaColor.textSecondary)
                    } else {
                        targetPreview
                    }
                }
                .padding(.top, PrismediaSpacing.medium)
            } label: {
                MetadataReviewSectionLabel(
                    title: "Current library item",
                    systemImage: "scope",
                    summary: item.title
                )
            }
            .padding(.horizontal, PrismediaSpacing.large)
            .padding(.vertical, PrismediaSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .prismediaPanel()
            .accessibilityIdentifier("identify.target-context")
        }

        private var targetPreview: some View {
            let item = thumbnail ?? fallbackThumbnail

            return HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
                EntityThumbnailCardView(
                    item: item,
                    layout: .compact,
                    preferredWidth: 64
                )

                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(PrismediaColor.textPrimary)
                        .lineLimit(3)

                    Text(item.kind.displayLabel)
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)

                    if let summary = item.summary, !summary.isEmpty {
                        Text(summary)
                            .font(.caption)
                            .foregroundStyle(PrismediaColor.textMuted)
                            .lineLimit(3)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(PrismediaSpacing.medium)
            .background(PrismediaColor.groupedContentBackground)
            .clipShape(.rect(cornerRadius: PrismediaRadius.badge))
            .contentShape(.rect)
            .accessibilityElement(children: .combine)
        }

        private var fallbackThumbnail: EntityThumbnail {
            EntityThumbnail(
                id: item.entityID,
                kind: item.entityKind,
                title: item.title,
                isNsfw: item.isNsfw,
                hasSourceMedia: true
            )
        }

    }

    #if DEBUG
        #Preview("Target Context Bar") {
            PreviewShell {
                IdentifyTargetContextBar(
                    item: IdentifyPreviewFixtures.reviewItem,
                    thumbnail: EntityThumbnail(
                        id: IdentifyPreviewFixtures.reviewItem.entityID,
                        kind: .movie,
                        title: "Arrival",
                        coverURL: "/preview/movie.jpg",
                        hasSourceMedia: true
                    )
                )
                .padding()
            }
        }

        #Preview("Target Context · Large Text") {
            PreviewShell {
                IdentifyTargetContextBar(item: IdentifyPreviewFixtures.reviewItem)
                    .padding()
                    .environment(\.dynamicTypeSize, .accessibility3)
            }
        }
    #endif
#endif
