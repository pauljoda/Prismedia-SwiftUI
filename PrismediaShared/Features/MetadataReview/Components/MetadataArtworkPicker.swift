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
                            HStack {
                                Text(kind.capitalized)
                                    .font(.subheadline.weight(.semibold))
                                Spacer(minLength: PrismediaSpacing.small)
                                Text(selectionSummary(for: kind))
                                    .font(.caption)
                                    .foregroundStyle(PrismediaColor.textSecondary)
                            }

                            LazyVGrid(
                                columns: [
                                    GridItem(
                                        .adaptive(minimum: minimumTileWidth(for: kind)),
                                        spacing: PrismediaSpacing.medium,
                                        alignment: .top
                                    )
                                ],
                                alignment: .leading,
                                spacing: PrismediaSpacing.medium
                            ) {
                                ForEach(images(for: kind), id: \.url) { image in
                                    let isSelected = selectedURL(for: kind) == image.url
                                    MetadataArtworkOptionButton(
                                        image: image,
                                        isSelected: isSelected,
                                        onSelect: {
                                            setSelectedURL(isSelected ? nil : image.url, for: kind)
                                        }
                                    )
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

        private func selectionSummary(for kind: String) -> String {
            let count = images(for: kind).count
            return selectedURL(for: kind) == nil
                ? "\(count) available"
                : "1 of \(count) selected"
        }

        private func minimumTileWidth(for kind: String) -> CGFloat {
            switch kind.lowercased() {
            case "backdrop", "thumbnail", "still": 180
            case "logo": 140
            default: 112
            }
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
