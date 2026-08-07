import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataProposalNodesView: View {
        let title: String
        let nodes: [AdministrativeEntityMetadataProposal]
        let selectedIDs: Set<String>
        let selectableIDs: Set<String>
        let onSetSelected: ((String, Bool) -> Void)?
        let onActivate: ((AdministrativeEntityMetadataProposal) -> Void)?
        @State private var isExpanded: Bool

        init(
            title: String,
            nodes: [AdministrativeEntityMetadataProposal],
            selectedIDs: Set<String>,
            selectableIDs: Set<String>,
            startsExpanded: Bool = true,
            onSetSelected: ((String, Bool) -> Void)?,
            onActivate: ((AdministrativeEntityMetadataProposal) -> Void)?
        ) {
            self.title = title
            self.nodes = nodes
            self.selectedIDs = selectedIDs
            self.selectableIDs = selectableIDs
            self.onSetSelected = onSetSelected
            self.onActivate = onActivate
            _isExpanded = State(initialValue: startsExpanded)
        }

        var body: some View {
            DisclosureGroup(isExpanded: $isExpanded) {
                LazyVStack(spacing: 0) {
                    if !selectableIDs.isEmpty, onSetSelected != nil {
                        HStack(spacing: PrismediaSpacing.small) {
                            Spacer()
                            Button("All") { setAllSelected(true) }
                                .buttonStyle(.borderless)
                                .accessibilityLabel("Select all \(title)")
                            Button("None") { setAllSelected(false) }
                                .buttonStyle(.borderless)
                                .accessibilityLabel("Deselect all \(title)")
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.vertical, PrismediaSpacing.small)
                    }
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

        private func setAllSelected(_ selected: Bool) {
            guard let onSetSelected else { return }
            for proposalID in selectableIDs.sorted() {
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
