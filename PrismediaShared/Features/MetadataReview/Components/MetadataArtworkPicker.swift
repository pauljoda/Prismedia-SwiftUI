import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataArtworkPicker: View {
        let proposal: AdministrativeEntityMetadataProposal
        @Binding var selection: MetadataReviewSelection
        @State private var isExpanded = true

        var body: some View {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                    ForEach(imageKinds, id: \.self) { kind in
                        MetadataArtworkKindPicker(
                            kind: kind,
                            images: images(for: kind),
                            selectedURL: selectedURLBinding(for: kind)
                        )
                    }
                }
                .padding(.top, PrismediaSpacing.medium)
            } label: {
                HStack {
                    Label("Artwork", systemImage: "photo.stack")
                        .font(.headline)
                    Spacer()
                    Text(selectionSummary)
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
            }
        }

        private var imageKinds: [String] {
            Array(Set(reviewableImages.map(\.kind))).sorted()
        }

        private func images(for kind: String) -> [AdministrativeImageCandidate] {
            reviewableImages.filter { $0.kind == kind }
        }

        private var reviewableImages: [AdministrativeImageCandidate] {
            MetadataReviewPolicy.reviewableImages(in: proposal)
        }

        private func selectedURL(for kind: String) -> String? {
            selection.selectedImagesByProposal[proposal.proposalID]?[kind]
        }

        private var selectionSummary: String {
            let selectedCount = imageKinds.count { selectedURL(for: $0) != nil }
            return "\(selectedCount) of \(imageKinds.count) kinds selected"
        }

        private func selectedURLBinding(for kind: String) -> Binding<String?> {
            Binding(
                get: { selectedURL(for: kind) },
                set: { url in
                    var selected = selection.selectedImagesByProposal[proposal.proposalID] ?? [:]
                    selected[kind] = url
                    selection.selectedImagesByProposal[proposal.proposalID] = selected
                }
            )
        }
    }

    #if DEBUG
        #Preview("Artwork Picker") {
            @Previewable @State var selection = MetadataReviewPolicy.seededSelection(
                for: MetadataReviewPreviewFixtures.proposal)
            PreviewShell {
                MetadataArtworkPicker(
                    proposal: MetadataReviewPreviewFixtures.proposal,
                    selection: $selection
                )
                .padding()
            }
        }
    #endif
#endif
