import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataProposalHeaderView: View {
        let proposal: AdministrativeEntityMetadataProposal
        var subtitle: String?
        var fallbackArtworkPath: String?

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                HStack(alignment: .top, spacing: PrismediaSpacing.large) {
                    EntityThumbnailCardView(
                        item: MetadataReviewThumbnailPolicy.thumbnail(
                            for: proposal,
                            fallbackArtworkPath: fallbackArtworkPath
                        ),
                        layout: .compact,
                        preferredWidth: 72
                    )

                    Text(proposal.patch.title ?? "Untitled Proposal")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(PrismediaColor.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)

                DisclosureGroup("Match details") {
                    VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                        LabeledContent("Provider", value: proposal.provider)
                        if let confidence = proposal.confidence {
                            LabeledContent(
                                "Confidence",
                                value: confidence.formatted(.percent.precision(.fractionLength(0)))
                            )
                        }
                        if let matchReason = proposal.matchReason, !matchReason.isEmpty {
                            Text(matchReason)
                        }
                        if let subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(.top, PrismediaSpacing.small)
                }
                .font(.subheadline)
                .foregroundStyle(PrismediaColor.textSecondary)
            }
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
