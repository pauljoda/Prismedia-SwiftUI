import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataProposalHeaderView: View {
        let proposal: AdministrativeEntityMetadataProposal

        var body: some View {
            HStack(alignment: .top, spacing: PrismediaSpacing.large) {
                RemotePosterImage(
                    path: artworkURL,
                    fallbackSeed: proposal.patch.title ?? proposal.proposalID,
                    systemImage: "photo"
                )
                .frame(width: 72, height: 104)
                .clipShape(.rect(cornerRadius: PrismediaRadius.compact))

                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    Text(proposal.patch.title ?? "Untitled Proposal")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(PrismediaColor.textPrimary)
                    Text(proposal.targetKind)
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)
                    HStack(spacing: PrismediaSpacing.medium) {
                        if let confidence = proposal.confidence {
                            Label(
                                confidence.formatted(.percent.precision(.fractionLength(0))),
                                systemImage: "checkmark.seal"
                            )
                        }
                        Label(proposal.provider, systemImage: "puzzlepiece.extension")
                    }
                    .font(.caption)
                    .foregroundStyle(PrismediaColor.textMuted)
                    if let matchReason = proposal.matchReason, !matchReason.isEmpty {
                        Text(matchReason)
                            .font(.caption2)
                            .foregroundStyle(PrismediaColor.textMuted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
        }

        private var artworkURL: String? {
            proposal.images.first { ["poster", "cover", "thumbnail", "backdrop"].contains($0.kind) }?.url
        }
    }

    #if DEBUG
        #Preview("Proposal Header") {
            PreviewShell {
                MetadataProposalHeaderView(proposal: MetadataReviewPreviewFixtures.proposal)
                    .padding()
            }
        }
    #endif
#endif
