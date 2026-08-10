import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataProposalHeaderView: View {
        let proposal: AdministrativeEntityMetadataProposal
        var subtitle: String?
        var fallbackArtworkPath: String?

        var body: some View {
            HStack(alignment: .top, spacing: PrismediaSpacing.large) {
                EntityThumbnailCardView(
                    item: MetadataReviewThumbnailPolicy.thumbnail(
                        for: proposal,
                        fallbackArtworkPath: fallbackArtworkPath
                    ),
                    layout: .compact,
                    preferredWidth: 72
                )

                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    Text(proposal.patch.title ?? "Untitled Proposal")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(PrismediaColor.textPrimary)

                    HStack(spacing: PrismediaSpacing.small) {
                        Text(proposal.targetKind.rawValue)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, PrismediaSpacing.small)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().strokeBorder(PrismediaColor.textMuted.opacity(0.5))
                            )
                            .foregroundStyle(PrismediaColor.textSecondary)
                        if let subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.caption.monospaced())
                                .foregroundStyle(PrismediaColor.textSecondary)
                        }
                    }

                    HStack(spacing: PrismediaSpacing.medium) {
                        if let confidence = proposal.confidence {
                            Label(
                                confidence.formatted(.percent.precision(.fractionLength(0))),
                                systemImage: "checkmark.seal"
                            )
                        }
                        Label(proposal.provider, systemImage: "puzzlepiece.extension")
                        if let matchReason = proposal.matchReason, !matchReason.isEmpty {
                            Text(matchReason)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(PrismediaColor.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
        }
    }

    #if DEBUG
        #Preview("Proposal Header") {
            PreviewShell {
                MetadataProposalHeaderView(
                    proposal: MetadataReviewPreviewFixtures.proposal,
                    subtitle: "tmdb:329865"
                )
                .padding()
            }
        }
    #endif
#endif
