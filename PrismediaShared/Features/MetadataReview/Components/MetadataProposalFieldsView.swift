import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataProposalFieldsView: View {
        let proposal: AdministrativeEntityMetadataProposal
        let selection: Binding<MetadataReviewSelection>?
        let currentValues: [MetadataReviewField: String]
        @State private var isExpanded = true

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
                !MetadataReviewPolicy.fieldValue($0, in: proposal).isEmpty
            }
        }

        private func fieldRow(_ field: MetadataReviewField) -> some View {
            HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
                if let selection {
                    Toggle("", isOn: fieldBinding(field, selection: selection))
                        .labelsHidden()
                        .accessibilityLabel("Apply \(field.label)")
                }
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
            .padding(.vertical, PrismediaSpacing.small)
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
