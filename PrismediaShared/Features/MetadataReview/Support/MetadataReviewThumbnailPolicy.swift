import Foundation

enum MetadataReviewThumbnailPolicy {
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
