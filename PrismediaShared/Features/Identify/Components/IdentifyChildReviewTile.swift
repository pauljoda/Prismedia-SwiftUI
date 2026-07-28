import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifyChildReviewTile: View {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
        let item: IdentifyChildReviewItem
        let isSelected: Bool
        let onSetSelected: (Bool) -> Void
        let onActivate: (AdministrativeEntityMetadataProposal) -> Void

        var body: some View {
            ZStack(alignment: .topTrailing) {
                if let proposal = item.proposal {
                    Button {
                        onActivate(proposal)
                    } label: {
                        card
                    }
                    .buttonStyle(.plain)
                    .contentShape(.rect)
                    .accessibilityHint("Reviews this child proposal")
                } else {
                    card
                }

                if item.proposal != nil {
                    Button {
                        onSetSelected(!isSelected)
                    } label: {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(
                                isSelected
                                    ? artworkPrimaryAccent
                                    : PrismediaColor.textMuted
                            )
                            .frame(width: 44, height: 44)
                            .background(
                                PrismediaColor.groupedContentBackground.opacity(0.82),
                                in: .circle
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isSelected ? "Exclude child" : "Include child")
                }
            }
            .accessibilityElement(children: .contain)
        }

        private var card: some View {
            EntityThumbnailCardView(item: presentationThumbnail, layout: .grid)
                .saturation(item.state == .matched ? 1 : 0)
                .opacity(item.state == .matched ? 1 : 0.52)
                .overlay {
                    if item.state != .matched {
                        statusOverlay
                    }
                }
        }

        private var presentationThumbnail: EntityThumbnail {
            guard let proposal = item.proposal else { return item.entity }
            return EntityThumbnail(
                id: item.entity.id,
                kind: EntityKind(rawValue: proposal.targetKind),
                title: proposal.patch.title ?? item.entity.title,
                subtitle: item.entity.subtitle,
                summary: proposal.patch.description ?? item.entity.summary,
                parentEntityID: item.entity.parentEntityID,
                parentKind: item.entity.parentKind,
                sortOrder: item.entity.sortOrder,
                coverURL: proposalArtworkPath ?? item.entity.coverURL,
                coverThumbURL: item.entity.coverThumbURL,
                coverThumb2xURL: item.entity.coverThumb2xURL,
                meta: item.entity.meta,
                isNsfw: item.entity.isNsfw,
                isOrganized: item.entity.isOrganized,
                hasSourceMedia: item.entity.hasSourceMedia
            )
        }

        @ViewBuilder
        private var statusOverlay: some View {
            ZStack {
                PrismediaColor.background.opacity(0.62)
                VStack(spacing: PrismediaSpacing.small) {
                    switch item.state {
                    case .loading:
                        ProgressView()
                        Text("Identifying…")
                    case .queued:
                        Image(systemName: "clock")
                        Text("Queued")
                    case .noMatch:
                        Image(systemName: "questionmark")
                        Text("No match found")
                    case .matched:
                        EmptyView()
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(PrismediaColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding()
            }
            .clipShape(.rect(cornerRadius: PrismediaRadius.badge))
        }

        private var proposalArtworkPath: String? {
            guard let proposal = item.proposal else { return nil }
            let images = MetadataReviewPolicy.reviewableImages(in: proposal)
            let preferredKinds = ["poster", "cover", "thumbnail", "still", "backdrop"]
            return preferredKinds.lazy.compactMap { kind in
                images.first { $0.kind.caseInsensitiveCompare(kind) == .orderedSame }?.url
            }.first ?? images.first?.url
        }
    }

    #if DEBUG
        #Preview("Identify Child · Loading") {
            PreviewShell {
                IdentifyChildReviewTile(
                    item: IdentifyPreviewFixtures.cascadeReviewItems[1],
                    isSelected: false,
                    onSetSelected: { _ in },
                    onActivate: { _ in }
                )
                .frame(width: 160)
                .padding()
            }
        }
    #endif
#endif
