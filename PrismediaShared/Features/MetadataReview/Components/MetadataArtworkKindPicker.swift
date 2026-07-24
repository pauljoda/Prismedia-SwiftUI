import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataArtworkKindPicker: View {
        let kind: String
        let images: [AdministrativeImageCandidate]
        @Binding var selectedURL: String?
        @State private var isExpanded = true

        var body: some View {
            DisclosureGroup(isExpanded: $isExpanded) {
                LazyVGrid(
                    columns: [
                        GridItem(
                            .adaptive(minimum: minimumTileWidth),
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
                HStack {
                    Text(kind.capitalized)
                        .font(.subheadline.weight(.semibold))
                    Spacer(minLength: PrismediaSpacing.small)
                    Text(selectionSummary)
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
            }
        }

        private var selectionSummary: String {
            selectedURL == nil
                ? "\(images.count) available"
                : "1 of \(images.count) selected"
        }

        private var minimumTileWidth: CGFloat {
            switch kind.lowercased() {
            case "backdrop", "header", "thumbnail", "still": 180
            case "logo": 140
            default: 112
            }
        }
    }

    #if DEBUG
        #Preview("Artwork Kind · Poster") {
            @Previewable @State var selectedURL: String?
            PreviewShell {
                MetadataArtworkKindPicker(
                    kind: "poster",
                    images: MetadataReviewPreviewFixtures.proposal.images,
                    selectedURL: $selectedURL
                )
                .padding()
            }
        }
    #endif
#endif
