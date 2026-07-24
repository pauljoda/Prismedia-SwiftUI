import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataProposalReviewView: View {
        let proposal: AdministrativeEntityMetadataProposal
        let headerSubtitle: String?
        let fallbackArtworkPath: String?
        let selection: Binding<MetadataReviewSelection>?
        let currentValues: [MetadataReviewField: String]
        let selectedProposalIDs: Set<String>
        let selectableProposalIDs: Set<String>
        let childrenTitle: String
        let displayedChildren: [AdministrativeEntityMetadataProposal]?
        let existingTagTitles: Set<String>
        let onSetProposalSelected: ((String, Bool) -> Void)?
        let onActivateProposal: ((AdministrativeEntityMetadataProposal) -> Void)?

        init(
            proposal: AdministrativeEntityMetadataProposal,
            headerSubtitle: String? = nil,
            fallbackArtworkPath: String? = nil,
            selection: Binding<MetadataReviewSelection>? = nil,
            currentValues: [MetadataReviewField: String] = [:],
            selectedProposalIDs: Set<String> = [],
            selectableProposalIDs: Set<String> = [],
            childrenTitle: String = "Items",
            displayedChildren: [AdministrativeEntityMetadataProposal]? = nil,
            existingTagTitles: Set<String> = [],
            onSetProposalSelected: ((String, Bool) -> Void)? = nil,
            onActivateProposal: ((AdministrativeEntityMetadataProposal) -> Void)? = nil
        ) {
            self.proposal = proposal
            self.headerSubtitle = headerSubtitle
            self.fallbackArtworkPath = fallbackArtworkPath
            self.selection = selection
            self.currentValues = currentValues
            self.selectedProposalIDs = selectedProposalIDs
            self.selectableProposalIDs = selectableProposalIDs
            self.childrenTitle = childrenTitle
            self.displayedChildren = displayedChildren
            self.existingTagTitles = existingTagTitles
            self.onSetProposalSelected = onSetProposalSelected
            self.onActivateProposal = onActivateProposal
        }

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraLarge) {
                MetadataProposalHeaderView(
                    proposal: proposal,
                    subtitle: headerSubtitle,
                    fallbackArtworkPath: fallbackArtworkPath
                )
                MetadataProposalFieldsView(
                    proposal: proposal,
                    selection: selection,
                    currentValues: currentValues,
                    excludedFields: separatelyReviewedFields
                )
                if let selection, !proposal.images.isEmpty {
                    MetadataArtworkPicker(proposal: proposal, selection: selection)
                }
                if let selection, !looseTags.isEmpty {
                    MetadataProposalTagsView(
                        proposalID: proposal.proposalID,
                        tags: looseTags,
                        existingTagTitles: existingTagTitles,
                        selection: selection
                    )
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
                        selectedIDs: selectedProposalIDs,
                        selectableIDs: selectableProposalIDs,
                        onSetSelected: onSetProposalSelected,
                        onActivate: onActivateProposal
                    )
                }
            }
            .padding(PrismediaSpacing.large)
            .prismediaPanel()
            .accessibilityIdentifier("metadata-review.proposal")
        }

        private var children: [AdministrativeEntityMetadataProposal] {
            displayedChildren ?? MetadataReviewPolicy.structuralChildren(of: proposal)
        }

        private var relationships: [AdministrativeEntityMetadataProposal] {
            MetadataReviewPolicy.relationships(of: proposal)
        }

        private var looseTags: [String] {
            let relationshipTitles = relationships.compactMap { relationship -> String? in
                guard relationship.targetKind.caseInsensitiveCompare("tag") == .orderedSame else {
                    return nil
                }
                return relationship.patch.title
            }
            return Array(Set(proposal.patch.tags)).filter { tag in
                !relationshipTitles.contains {
                    $0.caseInsensitiveCompare(tag) == .orderedSame
                }
            }.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        }

        private var separatelyReviewedFields: Set<MetadataReviewField> {
            guard selection != nil else { return [] }
            var fields = Set<MetadataReviewField>()
            if !proposal.images.isEmpty { fields.insert(.images) }
            if !proposal.patch.tags.isEmpty { fields.insert(.tags) }
            if relationships.contains(where: { $0.targetKind.caseInsensitiveCompare("person") == .orderedSame }) {
                fields.insert(.credits)
            }
            if relationships.contains(where: { $0.targetKind.caseInsensitiveCompare("studio") == .orderedSame }) {
                fields.insert(.studio)
            }
            return fields
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
