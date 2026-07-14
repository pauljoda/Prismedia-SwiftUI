import SwiftUI

struct EntityDetailHeaderView: View {
    let presentation: EntityDetailPresentation
    let previewPath: String?
    let showsArtwork: Bool
    let isMutating: Bool
    let canMutate: Bool
    let onRatingChange: (Int?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
            if showsArtwork, let heroPath = presentation.heroPath {
                EntityDetailHeroView(
                    heroPath: heroPath,
                    posterPath: posterPath,
                    title: presentation.detail.title,
                    systemImage: presentation.systemImage,
                    posterAspectRatio: presentation.detail.kind.thumbnailAspectRatio
                )
            } else if showsArtwork, let posterPath {
                EntityDetailPosterView(
                    posterPath: posterPath,
                    title: presentation.detail.title,
                    systemImage: presentation.systemImage,
                    aspectRatio: presentation.detail.kind.thumbnailAspectRatio
                )
            }

            EntityDetailIdentityView(
                presentation: presentation,
                isMutating: isMutating,
                canMutate: canMutate,
                horizontalPadding: horizontalPadding,
                onRatingChange: onRatingChange
            )
        }
    }

    private var posterPath: String? {
        presentation.posterPath ?? previewPath
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
    #Preview("Entity Detail Header · No Hero") {
        PreviewShell {
            ScrollView {
                EntityDetailHeaderView(
                    presentation: EntityDetailPresentation(detail: EntityDetailPreviewFixture.detail),
                    previewPath: "/preview/poster.jpg",
                    showsArtwork: true,
                    isMutating: false,
                    canMutate: true,
                    onRatingChange: { _ in }
                )
            }
        }
    }
#endif
