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
                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    EntityThumbnailArtworkFrame(
                        aspectRatio: MetadataReviewThumbnailPolicy.aspectRatio(for: image, in: proposal)
                    ) {
                        EntityThumbnailMediaView(
                            item: MetadataReviewThumbnailPolicy.thumbnail(for: image, in: proposal),
                            systemImage: proposal.targetKind.thumbnailFallbackSystemImage,
                            contentMode: .fit
                        )
                        .accessibilityHidden(true)
                    }
                    .overlay(alignment: .topTrailing) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(PrismediaColor.onAccent, PrismediaColor.accent)
                                .font(.title3)
                                .padding(PrismediaSpacing.small)
                        }
                    }
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                        Text(image.source)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(PrismediaColor.textPrimary)
                        if let dimensions {
                            Text(dimensions)
                                .font(.caption2.monospaced())
                                .foregroundStyle(PrismediaColor.textSecondary)
                        }
                    }
                    .padding(.horizontal, PrismediaSpacing.small)
                    .padding(.bottom, PrismediaSpacing.small)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(PrismediaColor.controlFill)
                .compositingGroup()
                .clipShape(tileShape)
                .overlay {
                    tileShape.stroke(
                        isSelected ? artworkPrimaryAccent : PrismediaColor.border,
                        lineWidth: isSelected ? PrismediaLayout.selectionBorder : PrismediaLayout.hairline
                    )
                }
                .contentShape(tileShape)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Use \(image.kind) artwork from \(image.source)")
            .accessibilityValue(dimensions ?? "Dimensions unavailable")
            .accessibilityHint(isSelected ? "Deselects this artwork" : "Selects this artwork")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }

        private var tileShape: RoundedRectangle {
            RoundedRectangle(cornerRadius: PrismediaRadius.compact, style: .continuous)
        }

        private var dimensions: String? {
            guard let width = image.width, let height = image.height, width > 0, height > 0 else { return nil }
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
