import SwiftUI

struct EntityDetailPosterView: View {
    let posterPath: String
    let title: String
    let systemImage: String
    let aspectRatio: Double

    var body: some View {
        HStack {
            EntityThumbnailArtworkFrame(aspectRatio: aspectRatio) {
                RemotePosterImage(
                    path: posterPath,
                    fallbackSeed: title,
                    systemImage: systemImage
                )
            }
            .frame(width: posterWidth)
            .compositingGroup()
            .clipShape(.rect(cornerRadius: PrismediaRadius.control))
            .overlay {
                RoundedRectangle(cornerRadius: PrismediaRadius.control, style: .continuous)
                    .stroke(PrismediaColor.onMedia.opacity(0.16), lineWidth: PrismediaLayout.hairline)
            }
            .shadow(color: PrismediaColor.background.opacity(0.58), radius: 24, y: 12)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, PrismediaSpacing.large)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Artwork for \(title)")
    }

    private var posterWidth: CGFloat {
        #if os(tvOS)
            aspectRatio > 1 ? 420 : 280
        #else
            aspectRatio > 1 ? 230 : 164
        #endif
    }

    private var horizontalPadding: CGFloat {
        #if os(tvOS)
            72
        #else
            20
        #endif
    }
}

#if DEBUG
    #Preview("Entity Detail Poster") {
        PreviewShell {
            EntityDetailPosterView(
                posterPath: "/preview/poster.jpg",
                title: "Signal in the Static",
                systemImage: "film",
                aspectRatio: 2.0 / 3.0
            )
        }
    }
#endif
