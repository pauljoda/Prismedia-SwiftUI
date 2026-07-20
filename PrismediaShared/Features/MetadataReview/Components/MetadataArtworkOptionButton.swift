import SwiftUI

#if os(iOS) || os(macOS)
    struct MetadataArtworkOptionButton: View {
        let image: AdministrativeImageCandidate
        let isSelected: Bool
        let onSelect: () -> Void

        var body: some View {
            Button(action: onSelect) {
                ZStack {
                    RemotePosterImage(
                        path: ProviderImagePreviewPolicy.previewURL(for: image.url, imageKind: image.kind),
                        fallbackSeed: image.url,
                        systemImage: "photo"
                    )
                    .aspectRatio(tileAspectRatio, contentMode: .fit)
                    .frame(maxWidth: .infinity)

                    VStack {
                        HStack {
                            Spacer(minLength: 0)
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(PrismediaColor.onAccent, PrismediaColor.accent)
                                    .font(.title3)
                            }
                        }

                        Spacer(minLength: 0)

                        HStack(spacing: PrismediaSpacing.extraSmall) {
                            Text(image.source)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            if let dimensions {
                                Text(dimensions)
                            }
                        }
                        .font(.caption2.monospaced())
                        .foregroundStyle(PrismediaColor.onMedia)
                        .padding(.horizontal, PrismediaSpacing.small)
                        .padding(.vertical, PrismediaSpacing.extraSmall)
                        .background(.black.opacity(0.72))
                    }
                    .padding(PrismediaSpacing.extraSmall)
                }
                .clipShape(tileShape)
                .overlay {
                    tileShape.stroke(
                        isSelected ? PrismediaColor.accent : PrismediaColor.border,
                        lineWidth: isSelected ? 2 : PrismediaLayout.hairline
                    )
                }
                .shadow(
                    color: isSelected ? PrismediaColor.accent.opacity(0.22) : .clear,
                    radius: PrismediaSpacing.medium
                )
                .contentShape(tileShape)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Use \(image.kind) artwork from \(image.source)")
            .accessibilityHint(isSelected ? "Deselects this artwork" : "Selects this artwork")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }

        private var tileShape: RoundedRectangle {
            RoundedRectangle(cornerRadius: PrismediaRadius.compact, style: .continuous)
        }

        private var tileAspectRatio: CGFloat {
            switch image.kind.lowercased() {
            case "poster", "cover":
                if let width = image.width, let height = image.height, width == height { return 1 }
                return 2 / 3
            case "backdrop", "thumbnail", "still":
                return 16 / 9
            default:
                return 2
            }
        }

        private var dimensions: String? {
            guard let width = image.width, let height = image.height else { return nil }
            return "\(width)×\(height)"
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
