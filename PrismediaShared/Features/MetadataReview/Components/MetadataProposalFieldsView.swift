import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataProposalFieldsView: View {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
        let proposal: AdministrativeEntityMetadataProposal
        let selection: Binding<MetadataReviewSelection>?
        let currentValues: [MetadataReviewField: String]
        let excludedFields: Set<MetadataReviewField>
        @State private var isExpanded = true

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
                HStack {
                    Label("Metadata", systemImage: "list.bullet.rectangle")
                        .font(.headline)
                    Spacer()
                    Text("\(visibleFields.count) fields")
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
            }
            .accessibilityIdentifier("metadata-review.fields")
        }

        private var visibleFields: [MetadataReviewField] {
            MetadataReviewField.allCases.filter {
                !excludedFields.contains($0)
                    && !MetadataReviewPolicy.fieldValue($0, in: proposal).isEmpty
            }
        }

        private func fieldRow(_ field: MetadataReviewField) -> some View {
            Group {
                if let selection {
                    Toggle(isOn: fieldBinding(field, selection: selection)) {
                        fieldDescription(field)
                    }
                    .toggleStyle(.switch)
                    .tint(artworkPrimaryAccent)
                    .padding(.trailing, PrismediaSpacing.small)
                    .accessibilityLabel("Apply \(field.label)")
                } else {
                    fieldDescription(field)
                }
            }
            .padding(.vertical, PrismediaSpacing.small)
        }

        private func fieldDescription(_ field: MetadataReviewField) -> some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Text(field.label)
                    .font(.subheadline.weight(.medium))
                if let current = currentValues[field], !current.isEmpty {
                    LabeledContent("Current", value: current)
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)
                    LabeledContent(
                        "Proposed",
                        value: MetadataReviewPolicy.fieldValue(field, in: proposal)
                    )
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
