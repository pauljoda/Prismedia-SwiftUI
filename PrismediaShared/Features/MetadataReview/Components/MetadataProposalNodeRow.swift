import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataProposalNodeRow: View {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
        let proposal: AdministrativeEntityMetadataProposal
        let isSelectable: Bool
        let isSelected: Bool
        let onSetSelected: ((Bool) -> Void)?
        let onActivate: ((AdministrativeEntityMetadataProposal) -> Void)?

        var body: some View {
            HStack(spacing: PrismediaSpacing.small) {
                if isSelectable, onActivate != nil {
                    Button {
                        onSetSelected?(!isSelected)
                    } label: {
                        selectionSymbol
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(isSelected ? artworkPrimaryAccent : PrismediaColor.textMuted)
                    .accessibilityLabel(isSelected ? "Exclude proposal" : "Include proposal")
                }

                if let onActivate {
                    Button {
                        onActivate(proposal)
                    } label: {
                        nodeLabel(trailingSymbol: "chevron.right")
                    }
                    .buttonStyle(.plain)
                    .contentShape(.rect)
                    .accessibilityHint("Review this proposal")
                } else if isSelectable {
                    Button {
                        onSetSelected?(!isSelected)
                    } label: {
                        HStack(spacing: PrismediaSpacing.small) {
                            selectionSymbol
                                .foregroundStyle(
                                    isSelected ? artworkPrimaryAccent : PrismediaColor.textMuted
                                )
                            nodeLabel(trailingSymbol: nil)
                        }
                    }
                    .buttonStyle(.plain)
                    .contentShape(.rect)
                } else {
                    nodeLabel(trailingSymbol: nil)
                }
            }
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }

        private var selectionSymbol: some View {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .frame(width: 44, height: 44)
        }

        private func nodeLabel(trailingSymbol: String?) -> some View {
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
                        HStack(spacing: PrismediaSpacing.small) {
                            Text(proposal.targetKind)
                            Text(proposal.targetEntityID == nil ? "New" : "Match")
                                .padding(.horizontal, PrismediaSpacing.small)
                                .padding(.vertical, 2)
                                .background(PrismediaColor.controlFill)
                                .clipShape(.capsule)
                                .foregroundStyle(
                                    proposal.targetEntityID == nil
                                        ? artworkPrimaryAccent
                                        : PrismediaColor.textSecondary
                                )
                        }
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)
                    }

                    Spacer()

                    if let trailingSymbol {
                        Image(systemName: trailingSymbol)
                            .font(.caption)
                            .foregroundStyle(
                                trailingSymbol == "checkmark.circle.fill"
                                    ? artworkPrimaryAccent
                                    : PrismediaColor.textMuted
                            )
                    }
                }
            }
        }

        private var artworkURL: String? {
            MetadataReviewPolicy.reviewableImages(in: proposal).first?.url
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
                    onActivate: { _ in }
                )
                .padding()
            }
        }
    #endif
#endif
