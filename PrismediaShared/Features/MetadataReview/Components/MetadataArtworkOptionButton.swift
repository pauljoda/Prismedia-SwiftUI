import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataArtworkOptionButton: View {
        let image: AdministrativeImageCandidate
        let isSelected: Bool
        let onSelect: () -> Void

        var body: some View {
            Button(action: onSelect) {
                ZStack(alignment: .topTrailing) {
                    RemotePosterImage(
                        path: image.url,
                        fallbackSeed: image.url,
                        systemImage: "photo"
                    )
                    .frame(width: 92, height: 132)
                    .clipShape(.rect(cornerRadius: PrismediaRadius.compact))

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(PrismediaColor.onMedia, PrismediaColor.accent)
                            .padding(PrismediaSpacing.extraSmall)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Use \(image.kind) artwork from \(image.source)")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
    }

    #if DEBUG
        #Preview("Artwork Option") {
            PreviewShell {
                MetadataArtworkOptionButton(
                    image: MetadataReviewPreviewFixtures.proposal.images[0],
                    isSelected: true,
                    onSelect: {}
                )
                .padding()
            }
        }
    #endif
#endif
