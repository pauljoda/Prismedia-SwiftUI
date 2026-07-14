import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataProposalNodeRow: View {
        let proposal: AdministrativeEntityMetadataProposal
        let isSelectable: Bool
        let isSelected: Bool
        let onSetSelected: ((Bool) -> Void)?
        let onActivate: ((AdministrativeEntityMetadataProposal) -> Void)?

        var body: some View {
            Button {
                if isSelectable {
                    onSetSelected?(!isSelected)
                } else {
                    onActivate?(proposal)
                }
            } label: {
                FullWidthButtonLabel {
                    HStack(spacing: PrismediaSpacing.medium) {
                        RemotePosterImage(
                            path: artworkURL,
                            fallbackSeed: proposal.patch.title ?? proposal.proposalID,
                            systemImage: "photo"
                        )
                        .frame(width: 48, height: 64)
                        .clipShape(.rect(cornerRadius: PrismediaRadius.badge))
                        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                            Text(proposal.patch.title ?? "Untitled")
                                .foregroundStyle(PrismediaColor.textPrimary)
                            Text(proposal.targetKind)
                                .font(.caption)
                                .foregroundStyle(PrismediaColor.textSecondary)
                        }
                        Spacer()
                        if isSelectable {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isSelected ? Color.accentColor : PrismediaColor.textMuted)
                        } else if onActivate != nil {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(PrismediaColor.textMuted)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }

        private var artworkURL: String? {
            proposal.images.first?.url
        }
    }

    #if DEBUG
        #Preview("Proposal Node") {
            PreviewShell {
                MetadataProposalNodeRow(
                    proposal: MetadataReviewPreviewFixtures.proposal.relationships[0],
                    isSelectable: true,
                    isSelected: true,
                    onSetSelected: { _ in },
                    onActivate: nil
                )
                .padding()
            }
        }
    #endif
#endif
