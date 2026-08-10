import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestIdentifyReviewPage<LeadingContent: View, TrailingContent: View>: View {
        @Environment(\.artworkPrimaryAccent) private var inheritedPrimaryAccent
        let navigationTitle: String
        let proposal: AdministrativeEntityMetadataProposal
        let headerSubtitle: String?
        let fallbackArtworkPath: String?
        @Binding var selection: MetadataReviewSelection
        @Binding var artworkPalette: ArtworkPalette?
        let currentValues: [MetadataReviewField: String]
        let selectedProposalIDs: Set<String>
        let selectableProposalIDs: Set<String>
        let identifyingProposalIDs: Set<String>
        let childrenTitle: String
        let displayedChildren: [AdministrativeEntityMetadataProposal]?
        let existingTagTitles: Set<String>
        let onSetProposalSelected: ((String, Bool) -> Void)?
        let onActivateProposal: ((AdministrativeEntityMetadataProposal) -> Void)?
        @ViewBuilder let leadingContent: LeadingContent
        @ViewBuilder let trailingContent: TrailingContent

        init(
            navigationTitle: String,
            proposal: AdministrativeEntityMetadataProposal,
            headerSubtitle: String? = nil,
            fallbackArtworkPath: String? = nil,
            selection: Binding<MetadataReviewSelection>,
            artworkPalette: Binding<ArtworkPalette?>,
            currentValues: [MetadataReviewField: String] = [:],
            selectedProposalIDs: Set<String> = [],
            selectableProposalIDs: Set<String> = [],
            identifyingProposalIDs: Set<String> = [],
            childrenTitle: String = "Items",
            displayedChildren: [AdministrativeEntityMetadataProposal]? = nil,
            existingTagTitles: Set<String> = [],
            onSetProposalSelected: ((String, Bool) -> Void)? = nil,
            onActivateProposal: ((AdministrativeEntityMetadataProposal) -> Void)? = nil,
            @ViewBuilder leadingContent: () -> LeadingContent,
            @ViewBuilder trailingContent: () -> TrailingContent
        ) {
            self.navigationTitle = navigationTitle
            self.proposal = proposal
            self.headerSubtitle = headerSubtitle
            self.fallbackArtworkPath = fallbackArtworkPath
            _selection = selection
            _artworkPalette = artworkPalette
            self.currentValues = currentValues
            self.selectedProposalIDs = selectedProposalIDs
            self.selectableProposalIDs = selectableProposalIDs
            self.identifyingProposalIDs = identifyingProposalIDs
            self.childrenTitle = childrenTitle
            self.displayedChildren = displayedChildren
            self.existingTagTitles = existingTagTitles
            self.onSetProposalSelected = onSetProposalSelected
            self.onActivateProposal = onActivateProposal
            self.leadingContent = leadingContent()
            self.trailingContent = trailingContent()
        }

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraLarge) {
                    leadingContent
                    MetadataProposalReviewView(
                        proposal: proposal,
                        headerSubtitle: headerSubtitle,
                        fallbackArtworkPath: fallbackArtworkPath,
                        selection: $selection,
                        currentValues: currentValues,
                        selectedProposalIDs: selectedProposalIDs,
                        selectableProposalIDs: selectableProposalIDs,
                        identifyingProposalIDs: identifyingProposalIDs,
                        childrenTitle: childrenTitle,
                        displayedChildren: displayedChildren,
                        existingTagTitles: existingTagTitles,
                        onSetProposalSelected: onSetProposalSelected,
                        onActivateProposal: onActivateProposal
                    )
                    trailingContent
                }
                .id(proposal.proposalID)
                .padding()
            }
            .prismediaScreenBackground(palette: artworkPalette)
            .navigationTitle(navigationTitle)
            .environment(\.artworkPalette, artworkPalette)
            .environment(
                \.artworkPrimaryAccent,
                artworkPalette?.primary.color ?? inheritedPrimaryAccent
            )
            .prismediaArtworkPalette(
                for: MetadataReviewArtworkPolicy.primaryArtworkPath(
                    for: proposal,
                    fallback: fallbackArtworkPath
                ),
                palette: $artworkPalette
            )
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .accessibilityIdentifier("request-identify.review")
        }
    }

    #if DEBUG
        #Preview("Request & Identify Review Page") {
            @Previewable @State var selection = MetadataReviewPolicy.seededSelection(
                for: MetadataReviewPreviewFixtures.proposal
            )
            @Previewable @State var palette: ArtworkPalette?
            PreviewShell {
                NavigationStack {
                    RequestIdentifyReviewPage(
                        navigationTitle: "Review",
                        proposal: MetadataReviewPreviewFixtures.proposal,
                        selection: $selection,
                        artworkPalette: $palette,
                        leadingContent: { EmptyView() },
                        trailingContent: { EmptyView() }
                    )
                }
            }
        }
    #endif
#endif
