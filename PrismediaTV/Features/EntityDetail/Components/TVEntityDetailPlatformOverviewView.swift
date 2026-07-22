#if os(tvOS)
    import SwiftUI

    struct EntityDetailPlatformOverviewView<DefaultOverview: View>: View {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
        @Environment(\.artworkSecondaryText) private var artworkSecondaryText

        let presentation: EntityDetailPresentation
        let previewPath: String?
        let showsArtwork: Bool
        @ViewBuilder let defaultOverview: () -> DefaultOverview

        var body: some View {
            HStack(alignment: .top, spacing: PrismediaSpacing.extraExtraLarge) {
                EntityThumbnailArtworkFrame(aspectRatio: artworkAspectRatio) {
                    RemotePosterImage(
                        path: presentation.posterPath,
                        previewPath: previewPath,
                        fallbackSeed: presentation.detail.title,
                        systemImage: presentation.systemImage
                    )
                }
                .frame(width: artworkWidth)
                .compositingGroup()
                .clipShape(.rect(cornerRadius: PrismediaRadius.control))
                .overlay {
                    RoundedRectangle(cornerRadius: PrismediaRadius.control, style: .continuous)
                        .stroke(
                            PrismediaColor.onMedia.opacity(0.16),
                            lineWidth: PrismediaLayout.hairline
                        )
                }
                .shadow(color: PrismediaColor.background.opacity(0.58), radius: 24, y: 12)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                    Text(presentation.detail.kind.displayLabel.uppercased())
                        .font(.caption.weight(.bold))
                        .tracking(1.4)
                        .foregroundStyle(artworkPrimaryAccent)

                    Text(presentation.detail.title)
                        .font(.system(size: 54, weight: .bold))
                        .foregroundStyle(PrismediaColor.textPrimary)
                        .lineLimit(2)

                    if let description = presentation.description {
                        Text(description)
                            .font(.title3)
                            .foregroundStyle(artworkSecondaryText)
                            .lineSpacing(6)
                            .lineLimit(6)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("entity-detail.summary")
                    }
                }
                .frame(maxWidth: 960, alignment: .topLeading)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 72)
            .padding(.vertical, PrismediaSpacing.extraLarge)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("entity-detail.hero-information")
        }

        private var artworkAspectRatio: Double {
            presentation.detail.kind.thumbnailAspectRatio
        }

        private var artworkWidth: CGFloat {
            if artworkAspectRatio > 1 { return 460 }
            if artworkAspectRatio < 0.9 { return 280 }
            return 320
        }
    }

    #if DEBUG
        #Preview("TV Entity Detail Overview · Collection") {
            let source = EntityDetailPreviewFixture.detail
            let collection = EntityDetail(
                id: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
                kind: .collection,
                title: "Atmospheric Favorites",
                parentEntityID: nil,
                sortOrder: nil,
                hasSourceMedia: false,
                capabilities: source.capabilities,
                childrenByKind: [],
                relationships: []
            )

            PreviewShell(signedIn: true) {
                EntityDetailPlatformOverviewView(
                    presentation: EntityDetailPresentation(detail: collection),
                    previewPath: nil,
                    showsArtwork: true
                ) {
                    Text("Unused platform fallback")
                }
            }
            .frame(width: 1_920, height: 720)
        }
    #endif
#endif
