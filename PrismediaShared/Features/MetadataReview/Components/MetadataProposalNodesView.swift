import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataProposalNodesView: View {
        let title: String
        let nodes: [AdministrativeEntityMetadataProposal]
        let selectedIDs: Set<String>
        let selectableIDs: Set<String>
        let identifyingIDs: Set<String>
        let onSetSelected: ((String, Bool) -> Void)?
        let onActivate: ((AdministrativeEntityMetadataProposal) -> Void)?
        @State private var isExpanded: Bool

        init(
            title: String,
            nodes: [AdministrativeEntityMetadataProposal],
            selectedIDs: Set<String>,
            selectableIDs: Set<String>,
            identifyingIDs: Set<String> = [],
            startsExpanded: Bool = true,
            onSetSelected: ((String, Bool) -> Void)?,
            onActivate: ((AdministrativeEntityMetadataProposal) -> Void)?
        ) {
            self.title = title
            self.nodes = nodes
            self.selectedIDs = selectedIDs
            self.selectableIDs = selectableIDs
            self.identifyingIDs = identifyingIDs
            self.onSetSelected = onSetSelected
            self.onActivate = onActivate
            _isExpanded = State(initialValue: startsExpanded)
        }

        var body: some View {
            DisclosureGroup(isExpanded: $isExpanded) {
                LazyVStack(spacing: 0) {
                    if !groupSelectableIDs.isEmpty, onSetSelected != nil {
                        HStack(spacing: PrismediaSpacing.small) {
                            Button("All") { setAllSelected(true) }
                                .accessibilityLabel("Select all \(title)")
                            Button("None") { setAllSelected(false) }
                                .accessibilityLabel("Deselect all \(title)")
                            Spacer()
                        }
                        .buttonStyle(.glass)
                        .controlSize(.regular)
                        .padding(.vertical, PrismediaSpacing.small)
                    }
                    ForEach(nodes, id: \.proposalID) { node in
                        MetadataProposalNodeRow(
                            proposal: node,
                            isSelectable: groupSelectableIDs.contains(node.proposalID),
                            isSelected: selectedIDs.contains(node.proposalID),
                            isIdentifying: identifyingIDs.contains(node.proposalID),
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
                MetadataReviewSectionLabel(
                    title: title, systemImage: "square.grid.2x2", summary: selectionSummary
                )
            }
        }

        private var selectionSummary: String {
            if nodes.contains(where: { identifyingIDs.contains($0.proposalID) }) {
                return "identifying…"
            }
            guard !groupSelectableIDs.isEmpty else { return nodes.count.formatted() }
            let selectedCount = selectedIDs.intersection(groupSelectableIDs).count
            return "\(selectedCount) of \(groupSelectableIDs.count) selected"
        }

        private var groupSelectableIDs: Set<String> {
            MetadataReviewPolicy.selectableProposalIDs(in: nodes, from: selectableIDs)
        }

        private func setAllSelected(_ selected: Bool) {
            guard let onSetSelected else { return }
            for proposalID in groupSelectableIDs.sorted() {
                onSetSelected(proposalID, selected)
            }
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
