import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataArtworkPicker: View {
        let proposal: AdministrativeEntityMetadataProposal
        @Binding var selection: MetadataReviewSelection

        var body: some View {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                    ForEach(imageKinds, id: \.self) { kind in
                        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                            Text(kind.capitalized)
                                .font(.subheadline.weight(.medium))
                            ScrollView(.horizontal) {
                                LazyHStack(spacing: PrismediaSpacing.medium) {
                                    PrismediaButton(
                                        "None",
                                        systemImage: selectedURL(for: kind) == nil ? "checkmark.circle.fill" : "circle",
                                        surface: .embedded
                                    ) {
                                        setSelectedURL(nil, for: kind)
                                    }

                                    ForEach(images(for: kind), id: \.url) { image in
                                        MetadataArtworkOptionButton(
                                            image: image,
                                            isSelected: selectedURL(for: kind) == image.url,
                                            onSelect: { setSelectedURL(image.url, for: kind) }
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.top, PrismediaSpacing.small)
            } label: {
                Label("Artwork", systemImage: "photo.stack")
                    .font(.headline)
            }
        }

        private var imageKinds: [String] {
            Array(Set(proposal.images.map(\.kind))).sorted()
        }

        private func images(for kind: String) -> [AdministrativeImageCandidate] {
            proposal.images.filter { $0.kind == kind }
        }

        private func selectedURL(for kind: String) -> String? {
            selection.selectedImagesByProposal[proposal.proposalID]?[kind]
        }

        private func setSelectedURL(_ url: String?, for kind: String) {
            var selected = selection.selectedImagesByProposal[proposal.proposalID] ?? [:]
            selected[kind] = url
            selection.selectedImagesByProposal[proposal.proposalID] = selected
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
