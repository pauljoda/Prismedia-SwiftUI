import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifyChildrenReviewSection: View {
        let items: [IdentifyChildReviewItem]
        let selectedProposalIDs: Set<String>
        let cascadeRunning: Bool
        let onSetProposalSelected: (String, Bool) -> Void
        let onActivateProposal: (AdministrativeEntityMetadataProposal) -> Void
        @State private var isExpanded = true

        var body: some View {
            DisclosureGroup(isExpanded: $isExpanded) {
                LazyVGrid(
                    columns: [
                        GridItem(
                            .adaptive(minimum: 132),
                            spacing: PrismediaSpacing.medium,
                            alignment: .top
                        )
                    ],
                    alignment: .leading,
                    spacing: PrismediaSpacing.medium
                ) {
                    ForEach(items) { item in
                        IdentifyChildReviewTile(
                            item: item,
                            isSelected: item.proposal.map {
                                selectedProposalIDs.contains($0.proposalID)
                            } ?? false,
                            onSetSelected: { isSelected in
                                guard let proposalID = item.proposal?.proposalID else { return }
                                onSetProposalSelected(proposalID, isSelected)
                            },
                            onActivate: onActivateProposal
                        )
                    }
                }
                .padding(.top, PrismediaSpacing.medium)
            } label: {
                HStack(spacing: PrismediaSpacing.small) {
                    Label("Children", systemImage: "square.grid.2x2")
                        .font(.headline)
                    if cascadeRunning {
                        ProgressView()
                            .controlSize(.small)
                            .accessibilityLabel("Identifying children")
                    }
                    Spacer(minLength: PrismediaSpacing.small)
                    Text(selectionSummary)
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
            }
            .padding(PrismediaSpacing.large)
            .prismediaPanel()
            .accessibilityIdentifier("identify.review.children")
        }

        private var selectionSummary: String {
            let matched = items.compactMap(\.proposal)
            let selectedCount = matched.count {
                selectedProposalIDs.contains($0.proposalID)
            }
            if cascadeRunning {
                return "\(selectedCount) selected · identifying…"
            }
            return "\(selectedCount) of \(matched.count) selected"
        }
    }

    #if DEBUG
        #Preview("Identify Children · Cascade") {
            PreviewShell {
                ScrollView {
                    IdentifyChildrenReviewSection(
                        items: IdentifyPreviewFixtures.cascadeReviewItems,
                        selectedProposalIDs: ["narnia-child-1"],
                        cascadeRunning: true,
                        onSetProposalSelected: { _, _ in },
                        onActivateProposal: { _ in }
                    )
                    .padding()
                }
            }
        }
    #endif
#endif
