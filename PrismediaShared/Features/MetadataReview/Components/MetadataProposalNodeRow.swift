import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataProposalNodeRow: View {
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
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(isSelected ? Color.accentColor : PrismediaColor.textMuted)
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
                        nodeLabel(trailingSymbol: isSelected ? "checkmark.circle.fill" : "circle")
                    }
                    .buttonStyle(.plain)
                    .contentShape(.rect)
                } else {
                    nodeLabel(trailingSymbol: nil)
                }
            }
            .accessibilityAddTraits(isSelected ? .isSelected : [])
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
                        Text(proposal.targetKind)
                            .font(.caption)
                            .foregroundStyle(PrismediaColor.textSecondary)
                    }

                    Spacer()

                    if let trailingSymbol {
                        Image(systemName: trailingSymbol)
                            .font(.caption)
                            .foregroundStyle(
                                trailingSymbol == "checkmark.circle.fill"
                                    ? Color.accentColor
                                    : PrismediaColor.textMuted
                            )
                    }
                }
            }
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
