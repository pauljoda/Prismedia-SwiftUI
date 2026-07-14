import SwiftUI

struct EntityDetailHeroView: View {
    @Environment(\.artworkPalette) private var artworkPalette
    let heroPath: String
    let posterPath: String?
    let title: String
    let systemImage: String
    let posterAspectRatio: Double

    var body: some View {
        let posterHeight = posterWidth / posterAspectRatio

        ZStack(alignment: .topLeading) {
            RemotePosterImage(
                path: heroPath,
                fallbackSeed: title,
                systemImage: systemImage,
                contentMode: EntityDetailHeroArtworkPolicy.contentMode
            )
            .frame(maxWidth: .infinity)
            .frame(height: backdropHeight)
            .overlay {
                LinearGradient(
                    colors: [
                        PrismediaColor.background.opacity(0.05),
                        (artworkPalette?.background.color ?? PrismediaColor.background).opacity(0.96),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white, location: 0.64),
                        .init(color: .white.opacity(0.82), location: 0.78),
                        .init(color: Color.clear, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipped()

            if let posterPath {
                EntityThumbnailArtworkFrame(aspectRatio: posterAspectRatio) {
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
                .padding(.leading, horizontalPadding)
                .offset(y: backdropHeight - (posterHeight / 2))
            }
        }
        .frame(
            height: backdropHeight + (posterPath == nil ? 0 : posterHeight / 2),
            alignment: .top
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Hero artwork for \(title)")
    }

    private var posterWidth: CGFloat {
        #if os(tvOS)
            posterAspectRatio > 1 ? 520 : 340
        #else
            posterAspectRatio > 1 ? 230 : 164
        #endif
    }

    private var backdropHeight: CGFloat {
        #if os(tvOS)
            480
        #else
            250
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
    #Preview("Entity Detail Hero") {
        PreviewShell {
            EntityDetailHeroView(
                heroPath: "/preview/hero.jpg",
                posterPath: "/preview/poster.jpg",
                title: "Signal in the Static",
                systemImage: "film",
                posterAspectRatio: 2.0 / 3.0
            )
        }
    }
#endif
