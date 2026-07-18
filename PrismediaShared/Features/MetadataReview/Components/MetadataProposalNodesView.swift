import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataProposalNodesView: View {
        let title: String
        let nodes: [AdministrativeEntityMetadataProposal]
        let selectedIDs: Set<String>
        let selectableIDs: Set<String>
        let onSetSelected: ((String, Bool) -> Void)?
        let onActivate: ((AdministrativeEntityMetadataProposal) -> Void)?

        var body: some View {
            DisclosureGroup {
                LazyVStack(spacing: 0) {
                    ForEach(nodes, id: \.proposalID) { node in
                        MetadataProposalNodeRow(
                            proposal: node,
                            isSelectable: selectableIDs.contains(node.proposalID),
                            isSelected: selectedIDs.contains(node.proposalID),
                            onSetSelected: onSetSelected.map { callback in
                                { callback(node.proposalID, $0) }
                            },
                            onActivate: onActivate
                        )
                        .padding(.vertical, PrismediaSpacing.small)
                        if node.proposalID != nodes.last?.proposalID { Divider() }
                    }
                }
            } label: {
                HStack {
                    Label(title, systemImage: "square.grid.2x2")
                        .font(.headline)
                    Spacer()
                    Text(selectionSummary)
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
            }
        }

        private var selectionSummary: String {
            guard !selectableIDs.isEmpty else { return nodes.count.formatted() }
            let selectedCount = selectedIDs.intersection(selectableIDs).count
            return "\(selectedCount) of \(selectableIDs.count) selected"
        }
    }

    #if DEBUG
        #Preview("Proposal Nodes · Dark") {
            PreviewShell {
                MetadataProposalNodesView(
                    title: "Related Metadata",
                    nodes: MetadataReviewPreviewFixtures.proposal.relationships,
                    selectedIDs: [],
                    selectableIDs: [],
                    onSetSelected: nil,
                    onActivate: { _ in }
                )
                .padding()
                .preferredColorScheme(.dark)
            }
        }
    #endif
#endif
