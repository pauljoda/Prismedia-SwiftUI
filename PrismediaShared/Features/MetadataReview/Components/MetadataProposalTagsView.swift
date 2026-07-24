import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataProposalTagsView: View {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
        let proposalID: String
        let tags: [String]
        let existingTagTitles: Set<String>
        @Binding var selection: MetadataReviewSelection
        @State private var isExpanded = false

        var body: some View {
            DisclosureGroup(isExpanded: $isExpanded) {
                LazyVStack(
                    alignment: .leading,
                    spacing: PrismediaSpacing.small
                ) {
                    ForEach(tags, id: \.self) { tag in
                        tagButton(tag)
                    }
                }
                .padding(.top, PrismediaSpacing.small)
            } label: {
                HStack {
                    Label("Tags", systemImage: "tag")
                        .font(.headline)
                    Spacer()
                    Text("\(selectedCount) of \(tags.count) selected")
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
            }
        }

        private func tagButton(_ tag: String) -> some View {
            let isSelected = selectedTags.contains(tag)
            let shape = RoundedRectangle(
                cornerRadius: PrismediaRadius.badge,
                style: .continuous
            )

            return Button {
                setSelected(!isSelected, tag: tag)
            } label: {
                HStack(spacing: PrismediaSpacing.small) {
                    Text(tag)
                        .lineLimit(3)
                        .minimumScaleFactor(0.85)
                        .allowsTightening(true)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                        .foregroundStyle(PrismediaColor.textPrimary)
                    Spacer(minLength: PrismediaSpacing.small)
                    Text(isExisting(tag) ? "Match" : "New")
                        .font(.caption2.monospaced())
                        .foregroundStyle(
                            isExisting(tag)
                                ? PrismediaColor.textSecondary
                                : artworkPrimaryAccent
                        )
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(
                            isSelected
                                ? artworkPrimaryAccent
                                : PrismediaColor.textMuted
                        )
                        .frame(width: 28, height: 28)
                }
                .padding(.horizontal, PrismediaSpacing.medium)
                .padding(.vertical, PrismediaSpacing.small)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .background(PrismediaColor.controlFill, in: shape)
                .overlay {
                    shape.stroke(
                        isSelected
                            ? artworkPrimaryAccent.opacity(0.5)
                            : PrismediaColor.borderSubtle,
                        lineWidth: 1
                    )
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(isSelected ? "Deselect" : "Select") \(tag)")
            .accessibilityValue(isExisting(tag) ? "Match existing tag" : "Create new tag")
        }

        private var selectedTags: Set<String> {
            selection.selectedTagsByProposal[proposalID] ?? []
        }

        private var selectedCount: Int {
            selectedTags.intersection(Set(tags)).count
        }

        private func setSelected(_ isSelected: Bool, tag: String) {
            var selected = selectedTags
            if isSelected {
                selected.insert(tag)
            } else {
                selected.remove(tag)
            }
            selection.selectedTagsByProposal[proposalID] = selected
        }

        private func isExisting(_ tag: String) -> Bool {
            existingTagTitles.contains {
                $0.caseInsensitiveCompare(tag) == .orderedSame
            }
        }
    }

    #if DEBUG
        #Preview("Proposal Tags · New and Merge") {
            @Previewable @State var selection = MetadataReviewPolicy.seededSelection(
                for: MetadataReviewPreviewFixtures.proposal
            )
            PreviewShell {
                MetadataProposalTagsView(
                    proposalID: MetadataReviewPreviewFixtures.proposal.proposalID,
                    tags: MetadataReviewPreviewFixtures.proposal.patch.tags,
                    existingTagTitles: ["Drama"],
                    selection: $selection
                )
                .padding()
            }
        }
    #endif
#endif
