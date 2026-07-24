import SwiftUI

#if os(iOS) || os(macOS)
    /// Expandable "To Identify" context showing which library item the current
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
                    if let thumbnail {
                        EntityThumbnailCardView(item: thumbnail, layout: .list)
                    } else if isLoading {
                        HStack(spacing: PrismediaSpacing.small) {
                            ProgressView()
                            Text("Loading item preview…")
                        }
                        .frame(maxWidth: .infinity, minHeight: 88)
                        .foregroundStyle(PrismediaColor.textSecondary)
                    } else {
                        EntityThumbnailCardView(item: fallbackThumbnail, layout: .list)
                    }
                }
                .padding(.top, PrismediaSpacing.medium)
            } label: {
                HStack(spacing: PrismediaSpacing.medium) {
                    Image(systemName: "scope")
                        .foregroundStyle(PrismediaColor.textSecondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("To Identify")
                            .font(.caption2.smallCaps().weight(.semibold))
                            .foregroundStyle(PrismediaColor.textMuted)
                        HStack(spacing: PrismediaSpacing.small) {
                            Text(item.title)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)
                            Text(item.entityKind.rawValue)
                                .font(.caption2.monospaced())
                                .foregroundStyle(PrismediaColor.textSecondary)
                        }
                    }

                    Spacer(minLength: 0)

                    Text(statusLabel)
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
            }
            .padding(.horizontal, PrismediaSpacing.large)
            .padding(.vertical, PrismediaSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .prismediaPanel()
            .accessibilityIdentifier("identify.target-context")
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

        private var statusLabel: String {
            let state = IdentifyQueueState(rawServerValue: item.state)
            switch state {
            case .proposal: return "match found"
            case .choice: return "awaiting match"
            case .queued, .searching: return "searching…"
            default: return state.label.lowercased()
            }
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
    #endif
#endif
