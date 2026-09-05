import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataProposalDatesView: View {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
        let proposal: AdministrativeEntityMetadataProposal
        let selection: Binding<MetadataReviewSelection>?
        @State private var isExpanded = false

        var body: some View {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                    if let selection {
                        Toggle("Apply release dates", isOn: selectedBinding(selection))
                            .tint(artworkPrimaryAccent)
                    }
                    ForEach(dates, id: \.code) { date in
                        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                            Text(date.type?.displayName ?? titleCase(date.code))
                                .font(.subheadline)
                                .foregroundStyle(PrismediaColor.textSecondary)
                            Text(date.value)
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.top, PrismediaSpacing.medium)
            } label: {
                MetadataReviewSectionLabel(
                    title: "Release dates", systemImage: "calendar", summary: selectionSummary
                )
            }
            .accessibilityIdentifier("metadata-review.release-dates")
        }

        private var dates: [EntityDate] {
            MetadataReviewPolicy.proposedDates(in: proposal)
        }

        private var selectionSummary: String {
            guard let selection else { return "\(dates.count) dates" }
            let selected =
                selection.wrappedValue.selectedFieldsByProposal[proposal.proposalID]?.contains(.dates) == true
            return selected ? "\(dates.count) dates selected" : "Not selected"
        }

        private func selectedBinding(
            _ selection: Binding<MetadataReviewSelection>
        ) -> Binding<Bool> {
            Binding(
                get: {
                    selection.wrappedValue.selectedFieldsByProposal[proposal.proposalID]?.contains(.dates) == true
                },
                set: { selected in
                    var fields = selection.wrappedValue.selectedFieldsByProposal[proposal.proposalID] ?? []
                    if selected { fields.insert(.dates) } else { fields.remove(.dates) }
                    selection.wrappedValue.selectedFieldsByProposal[proposal.proposalID] = fields
                }
            )
        }

        private func titleCase(_ value: String) -> String {
            value.replacingOccurrences(of: "-", with: " ").capitalized
        }
    }
#endif

#if DEBUG && (os(iOS) || os(macOS))
    #Preview("Proposal Release Dates") {
        MetadataProposalDatesView(
            proposal: MetadataReviewPreviewFixtures.proposal,
            selection: nil
        )
        .padding()
        .preferredColorScheme(.dark)
    }
#endif
