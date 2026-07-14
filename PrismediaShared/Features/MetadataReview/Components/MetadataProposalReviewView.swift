import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataProposalReviewView: View {
        let proposal: AdministrativeEntityMetadataProposal
        let selection: Binding<MetadataReviewSelection>?
        let currentValues: [MetadataReviewField: String]
        let selectedProposalIDs: Set<String>
        let selectableProposalIDs: Set<String>
        let childrenTitle: String
        let onSetProposalSelected: ((String, Bool) -> Void)?
        let onActivateProposal: ((AdministrativeEntityMetadataProposal) -> Void)?

        init(
            proposal: AdministrativeEntityMetadataProposal,
            selection: Binding<MetadataReviewSelection>? = nil,
            currentValues: [MetadataReviewField: String] = [:],
            selectedProposalIDs: Set<String> = [],
            selectableProposalIDs: Set<String> = [],
            childrenTitle: String = "Items",
            onSetProposalSelected: ((String, Bool) -> Void)? = nil,
            onActivateProposal: ((AdministrativeEntityMetadataProposal) -> Void)? = nil
        ) {
            self.proposal = proposal
            self.selection = selection
            self.currentValues = currentValues
            self.selectedProposalIDs = selectedProposalIDs
            self.selectableProposalIDs = selectableProposalIDs
            self.childrenTitle = childrenTitle
            self.onSetProposalSelected = onSetProposalSelected
            self.onActivateProposal = onActivateProposal
        }

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraLarge) {
                MetadataProposalHeaderView(proposal: proposal)
                MetadataProposalFieldsView(
                    proposal: proposal,
                    selection: selection,
                    currentValues: currentValues
                )
                if let selection, !proposal.images.isEmpty {
                    MetadataArtworkPicker(proposal: proposal, selection: selection)
                }
                if !children.isEmpty {
                    MetadataProposalNodesView(
                        title: childrenTitle,
                        nodes: children,
                        selectedIDs: selectedProposalIDs,
                        selectableIDs: selectableProposalIDs,
                        onSetSelected: onSetProposalSelected,
                        onActivate: onActivateProposal
                    )
                }
                if !relationships.isEmpty {
                    MetadataProposalNodesView(
                        title: "Related Metadata",
                        nodes: relationships,
                        selectedIDs: [],
                        selectableIDs: [],
                        onSetSelected: nil,
                        onActivate: onActivateProposal
                    )
                }
            }
            .padding(PrismediaSpacing.large)
            .prismediaPanel()
            .accessibilityIdentifier("metadata-review.proposal")
        }

        private var children: [AdministrativeEntityMetadataProposal] {
            MetadataReviewPolicy.structuralChildren(of: proposal)
        }

        private var relationships: [AdministrativeEntityMetadataProposal] {
            MetadataReviewPolicy.relationships(of: proposal)
        }
    }

    #if DEBUG
        #Preview("Proposal Review") {
            @Previewable @State var selection = MetadataReviewPolicy.seededSelection(
                for: MetadataReviewPreviewFixtures.proposal)
            PreviewShell {
                ScrollView {
                    MetadataProposalReviewView(
                        proposal: MetadataReviewPreviewFixtures.proposal,
                        selection: $selection,
                        currentValues: [.title: "The Arrival"]
                    )
                    .padding()
                }
            }
        }

        #Preview("Proposal Review · Accessibility") {
            PreviewShell {
                ScrollView {
                    MetadataProposalReviewView(proposal: MetadataReviewPreviewFixtures.proposal)
                        .padding()
                }
                .environment(\.dynamicTypeSize, .accessibility3)
            }
        }
    #endif
#endif
