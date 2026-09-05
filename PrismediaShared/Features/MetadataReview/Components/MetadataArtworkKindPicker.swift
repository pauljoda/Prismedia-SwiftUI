import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataArtworkKindPicker: View {
        @ScaledMetric(relativeTo: .caption) private var minimumChoiceWidth = PrismediaLayout.artworkChoiceMinimumWidth
        let proposal: AdministrativeEntityMetadataProposal
        let kind: String
        let images: [AdministrativeImageCandidate]
        @Binding var selectedURL: String?
        @State private var isExpanded = true

        var body: some View {
            DisclosureGroup(isExpanded: $isExpanded) {
                LazyVGrid(
                    columns: [
                        GridItem(
                            .adaptive(minimum: minimumChoiceWidth),
                            spacing: PrismediaSpacing.medium,
                            alignment: .top
                        )
                    ],
                    alignment: .leading,
                    spacing: PrismediaSpacing.medium
                ) {
                    ForEach(images, id: \.url) { image in
                        let isSelected = selectedURL == image.url
                        MetadataArtworkOptionButton(
                            proposal: proposal,
                            image: image,
                            isSelected: isSelected,
                            onSelect: {
                                selectedURL = isSelected ? nil : image.url
                            }
                        )
                    }
                }
                .padding(.top, PrismediaSpacing.small)
            } label: {
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                    Text(kind.capitalized)
                        .font(.subheadline.weight(.semibold))
                    Text(selectionSummary)
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }

        private var selectionSummary: String {
            selectedURL == nil
                ? "\(images.count) available"
                : "1 of \(images.count) selected"
        }
    }

    #if DEBUG
        #Preview("Artwork Choices · Accessibility") {
            @Previewable @State var selectedURL: String?
            PreviewShell {
                ScrollView {
                    MetadataArtworkKindPicker(
                        proposal: MetadataReviewPreviewFixtures.proposal,
                        kind: "poster",
                        images: MetadataReviewPolicy.reviewableImages(
                            in: MetadataReviewPreviewFixtures.proposal
                        ).filter { $0.kind == "poster" },
                        selectedURL: $selectedURL
                    )
                    .padding()
                }
                .environment(\.dynamicTypeSize, .accessibility3)
            }
        }

        #Preview("Artwork Kind · Poster") {
            @Previewable @State var selectedURL: String?
            PreviewShell {
                MetadataArtworkKindPicker(
                    proposal: MetadataReviewPreviewFixtures.proposal,
                    kind: "poster",
                    images: MetadataReviewPolicy.reviewableImages(
                        in: MetadataReviewPreviewFixtures.proposal
                    ).filter { $0.kind == "poster" },
                    selectedURL: $selectedURL
                )
                .padding()
            }
        }
    #endif
#endif
