import Foundation

enum MetadataReviewThumbnailPolicy {
    /// Artwork choices show the complete candidate, not the crop used by the entity's library card.
    /// Missing or invalid dimensions fall back to the canonical entity frame.
    static func aspectRatio(
        for image: AdministrativeImageCandidate,
        in proposal: AdministrativeEntityMetadataProposal
    ) -> Double {
        guard let width = image.width, let height = image.height, width > 0, height > 0 else {
            return proposal.targetKind.thumbnailAspectRatio
        }
        return Double(width) / Double(height)
    }

    static func thumbnail(
        for proposal: AdministrativeEntityMetadataProposal,
        artworkPath: String? = nil,
        fallbackArtworkPath: String? = nil
    ) -> EntityThumbnail {
        EntityThumbnail(
            id: proposal.targetEntityID
                ?? EntityThumbnailPresentationIdentity.id(
                    namespace: "metadata-proposal",
                    value: proposal.proposalID
                ),
            kind: proposal.targetKind,
            title: proposal.patch.title ?? "Untitled Proposal",
            coverURL: artworkPath
                ?? MetadataReviewArtworkPolicy.primaryArtworkPath(
                    for: proposal,
                    fallback: fallbackArtworkPath
                )
        )
    }

    static func thumbnail(
        for image: AdministrativeImageCandidate,
        in proposal: AdministrativeEntityMetadataProposal
    ) -> EntityThumbnail {
        EntityThumbnail(
            id: EntityThumbnailPresentationIdentity.id(
                namespace: "metadata-artwork",
                value: "\(proposal.proposalID):\(image.kind):\(image.url)"
            ),
            kind: proposal.targetKind,
            title: proposal.patch.title ?? "Untitled Proposal",
            coverURL: ProviderImagePreviewPolicy.previewURL(
                for: image.url,
                imageKind: image.kind,
                targetKind: proposal.targetKind.rawValue
            )
        )
    }
}
