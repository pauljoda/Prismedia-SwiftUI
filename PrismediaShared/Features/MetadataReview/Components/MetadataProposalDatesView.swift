import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataProposalDatesView: View {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
        let proposal: AdministrativeEntityMetadataProposal
        let selection: Binding<MetadataReviewSelection>?

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                HStack {
                    Label("Release dates", systemImage: "calendar")
                        .font(.headline)
                    Spacer()
                    if let selection {
                        Toggle("Apply release dates", isOn: selectedBinding(selection))
                            .labelsHidden()
                            .tint(artworkPrimaryAccent)
                    }
                }

                if dates.isEmpty {
                    ContentUnavailableView {
                        Label("No release date data yet", systemImage: "calendar.badge.questionmark")
                    } description: {
                        Text("The metadata provider did not include any release milestones in this proposal.")
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(dates, id: \.code) { date in
                        LabeledContent(
                            date.type?.displayName ?? titleCase(date.code),
                            value: date.value
                        )
                    }
                }
            }
            .accessibilityIdentifier("metadata-review.release-dates")
        }

        private var dates: [EntityDate] {
            MetadataReviewPolicy.proposedDates(in: proposal)
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
