import SwiftUI

struct EntityDetailHeaderView: View {
    let presentation: EntityDetailPresentation
    let previewPath: String?
    let showsArtwork: Bool
    let isMutating: Bool
    let canMutate: Bool
    let onRatingChange: (Int?) -> Void

    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    var body: some View {
        #if os(iOS)
            if horizontalSizeClass == .regular, showsArtwork, presentation.heroPath == nil, let posterPath {
                // A page on one side of a folded iPhone Duo can be too narrow for the
                // title column beside the poster; it then stacks as on compact width.
                ViewThatFits(in: .horizontal) {
                    sideBySideHeader(posterPath: posterPath)
                    stackedHeader
                }
            } else {
                stackedHeader
            }
        #else
            stackedHeader
        #endif
    }

    /// Room for the title column beside the poster: the five-star rating row and a margin.
    private static let minimumIdentityWidth: CGFloat = 260

    /// Regular width puts the poster beside the title, so a wide page doesn't
    /// leave an empty half next to a phone-sized poster.
    private func sideBySideHeader(posterPath: String) -> some View {
        HStack(alignment: .top, spacing: 0) {
            EntityDetailPosterView(
                posterPath: posterPath,
                title: presentation.detail.title,
                systemImage: presentation.systemImage,
                kind: presentation.detail.kind
            )
            .fixedSize(horizontal: true, vertical: false)

            EntityDetailIdentityView(
                presentation: presentation,
                isMutating: isMutating,
                canMutate: canMutate,
                horizontalPadding: 0,
                onRatingChange: onRatingChange
            )
            .padding(.top, PrismediaSpacing.large)
            .frame(
                minWidth: Self.minimumIdentityWidth,
                idealWidth: Self.minimumIdentityWidth,
                maxWidth: .infinity,
                alignment: .leading
            )
            .padding(.trailing, horizontalPadding)
        }
    }

    private var stackedHeader: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
            if showsArtwork, let heroPath = presentation.heroPath {
                EntityDetailHeroView(
                    heroPath: heroPath,
                    posterPath: posterPath,
                    title: presentation.detail.title,
                    systemImage: presentation.systemImage,
                    posterKind: presentation.detail.kind
                )
            } else if showsArtwork, let posterPath {
                EntityDetailPosterView(
                    posterPath: posterPath,
                    title: presentation.detail.title,
                    systemImage: presentation.systemImage,
                    kind: presentation.detail.kind
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
            PrismediaLayout.televisionContentInset
        #else
            PrismediaSpacing.extraLarge
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
