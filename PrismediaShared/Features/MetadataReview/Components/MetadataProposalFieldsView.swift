import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataProposalFieldsView: View {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
        let proposal: AdministrativeEntityMetadataProposal
        let selection: Binding<MetadataReviewSelection>?
        let currentValues: [MetadataReviewField: String]
        let excludedFields: Set<MetadataReviewField>
        @State private var isExpanded = false

        init(
            proposal: AdministrativeEntityMetadataProposal,
            selection: Binding<MetadataReviewSelection>?,
            currentValues: [MetadataReviewField: String],
            excludedFields: Set<MetadataReviewField> = []
        ) {
            self.proposal = proposal
            self.selection = selection
            self.currentValues = currentValues
            self.excludedFields = excludedFields
        }

        var body: some View {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(spacing: 0) {
                    ForEach(visibleFields, id: \.self) { field in
                        fieldRow(field)
                        if field != visibleFields.last { Divider() }
                    }
                }
            } label: {
                MetadataReviewSectionLabel(
                    title: "Metadata", systemImage: "list.bullet.rectangle", summary: selectionSummary
                )
            }
            .accessibilityIdentifier("metadata-review.fields")
        }

        private var visibleFields: [MetadataReviewField] {
            MetadataReviewField.allCases.filter {
                !excludedFields.contains($0)
                    && !MetadataReviewPolicy.fieldValue($0, in: proposal).isEmpty
            }
        }

        private var selectionSummary: String {
            guard let selection else { return "\(visibleFields.count) fields" }
            let selected = selection.wrappedValue.selectedFieldsByProposal[proposal.proposalID] ?? []
            return "\(selected.intersection(visibleFields).count) of \(visibleFields.count) selected"
        }

        private func fieldRow(_ field: MetadataReviewField) -> some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                if let selection {
                    Toggle(isOn: fieldBinding(field, selection: selection)) {
                        Text(field.label)
                            .font(.subheadline.weight(.medium))
                    }
                    .toggleStyle(.switch)
                    .tint(artworkPrimaryAccent)
                    .padding(.trailing, PrismediaSpacing.small)
                    .accessibilityLabel("Apply \(field.label)")
                    fieldDescription(field)
                } else {
                    fieldDescription(field)
                }
            }
            .padding(.vertical, PrismediaSpacing.small)
        }

        private func fieldDescription(_ field: MetadataReviewField) -> some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                if selection == nil {
                    Text(field.label)
                        .font(.subheadline.weight(.medium))
                }
                if let current = currentValues[field], !current.isEmpty {
                    Text("Current")
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)
                    Text(current).font(.callout)
                        .foregroundStyle(PrismediaColor.textSecondary)
                    Text("Proposed")
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)
                    Text(MetadataReviewPolicy.fieldValue(field, in: proposal))
                        .font(.callout)
                } else {
                    Text(MetadataReviewPolicy.fieldValue(field, in: proposal))
                        .font(.callout)
                        .foregroundStyle(PrismediaColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        private func fieldBinding(
            _ field: MetadataReviewField,
            selection: Binding<MetadataReviewSelection>
        ) -> Binding<Bool> {
            Binding(
                get: {
                    selection.wrappedValue.selectedFieldsByProposal[proposal.proposalID]?
                        .contains(field) == true
                },
                set: { isSelected in
                    var fields = selection.wrappedValue.selectedFieldsByProposal[proposal.proposalID] ?? []
                    if isSelected { fields.insert(field) } else { fields.remove(field) }
                    selection.wrappedValue.selectedFieldsByProposal[proposal.proposalID] = fields
                }
            )
        }
    }

    #if DEBUG
        #Preview("Selectable Metadata") {
            @Previewable @State var selection = MetadataReviewPolicy.seededSelection(
                for: MetadataReviewPreviewFixtures.proposal)
            PreviewShell {
                MetadataProposalFieldsView(
                    proposal: MetadataReviewPreviewFixtures.proposal,
                    selection: $selection,
                    currentValues: [.title: "The Arrival"]
                )
                .padding()
            }
        }
    #endif
#endif
