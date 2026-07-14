import SwiftUI

/// Owns thumbnail media geometry so asynchronously loaded artwork can never
/// change the size of its grid cell.
public struct EntityThumbnailArtworkFrame<Artwork: View, Decoration: View>: View {
    private let aspectRatio: Double
    private let artwork: Artwork
    private let decoration: Decoration

    public init(
        aspectRatio: Double,
        @ViewBuilder artwork: () -> Artwork,
        @ViewBuilder decoration: () -> Decoration
    ) {
        self.aspectRatio = aspectRatio
        self.artwork = artwork()
        self.decoration = decoration()
    }

    public var body: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                artwork
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .clipped()
            .overlay {
                decoration
            }
    }
}

extension EntityThumbnailArtworkFrame where Decoration == EmptyView {
    public init(
        aspectRatio: Double,
        @ViewBuilder artwork: () -> Artwork
    ) {
        self.init(aspectRatio: aspectRatio, artwork: artwork) {
            EmptyView()
        }
    }
}

#if DEBUG
    #Preview("Mismatched Artwork Clipped to Frame") {
        HStack(alignment: .top, spacing: PrismediaSpacing.large) {
            EntityThumbnailArtworkFrame(aspectRatio: 2.0 / 3.0) {
                LinearGradient(
                    colors: [
                        PrismediaColor.spectrumBlue,
                        PrismediaColor.spectrumViolet,
                        PrismediaColor.spectrumMagenta,
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .aspectRatio(16.0 / 9.0, contentMode: .fill)
            }
            .frame(width: 150)
            .background(PrismediaColor.groupedContentBackground)

            EntityThumbnailArtworkFrame(aspectRatio: 16.0 / 9.0) {
                LinearGradient(
                    colors: [PrismediaColor.spectrumOrange, PrismediaColor.spectrumYellow],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .aspectRatio(2.0 / 3.0, contentMode: .fill)
            }
            .frame(width: 190)
            .background(PrismediaColor.groupedContentBackground)
        }
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }
#endif
