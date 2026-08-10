import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataArtworkOptionButton: View {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
        let proposal: AdministrativeEntityMetadataProposal
        let image: AdministrativeImageCandidate
        let isSelected: Bool
        let onSelect: () -> Void

        var body: some View {
            Button(action: onSelect) {
                ZStack {
                    EntityThumbnailCardView(
                        item: MetadataReviewThumbnailPolicy.thumbnail(
                            for: image,
                            in: proposal
                        ),
                        layout: .compact
                    )
                    .frame(maxWidth: .infinity)

                    VStack {
                        HStack {
                            Spacer(minLength: 0)
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(PrismediaColor.onAccent, artworkPrimaryAccent)
                                    .font(.title3)
                            }
                        }

                        Spacer(minLength: 0)

                        HStack(spacing: PrismediaSpacing.extraSmall) {
                            Text(image.source)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            if let dimensions {
                                Text(dimensions)
                            }
                        }
                        .font(.caption2.monospaced())
                        .foregroundStyle(PrismediaColor.onMedia)
                        .padding(.horizontal, PrismediaSpacing.small)
                        .padding(.vertical, PrismediaSpacing.extraSmall)
                        .background(.black.opacity(0.72))
                    }
                    .padding(PrismediaSpacing.extraSmall)
                }
                .clipShape(tileShape)
                .overlay {
                    tileShape.stroke(
                        isSelected ? artworkPrimaryAccent : PrismediaColor.border,
                        lineWidth: isSelected ? 2 : PrismediaLayout.hairline
                    )
                }
                .shadow(
                    color: isSelected ? artworkPrimaryAccent.opacity(0.22) : .clear,
                    radius: PrismediaSpacing.medium
                )
                .contentShape(tileShape)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Use \(image.kind) artwork from \(image.source)")
            .accessibilityHint(isSelected ? "Deselects this artwork" : "Selects this artwork")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }

        private var tileShape: RoundedRectangle {
            RoundedRectangle(cornerRadius: PrismediaRadius.compact, style: .continuous)
        }

        private var dimensions: String? {
            guard let width = image.width, let height = image.height else { return nil }
            return "\(width)×\(height)"
        }
    }

    #if DEBUG
        #Preview("Artwork Option") {
            PreviewShell {
                MetadataArtworkOptionButton(
                    proposal: MetadataReviewPreviewFixtures.proposal,
                    image: MetadataReviewPreviewFixtures.proposal.images[0],
                    isSelected: true,
                    onSelect: {}
                )
                .padding()
            }
        }
    #endif
#endif
