import Foundation

enum MetadataReviewArtworkPolicy {
    static func primaryArtworkPath(
        for proposal: AdministrativeEntityMetadataProposal,
        fallback: String? = nil
    ) -> String? {
        let images = MetadataReviewPolicy.reviewableImages(in: proposal)
        let image = ["poster", "cover", "thumbnail", "backdrop"]
            .lazy
            .compactMap { kind in images.first { $0.kind.lowercased() == kind } }
            .first
        guard let image else { return fallback }
        return ProviderImagePreviewPolicy.previewURL(
            for: image.url,
            imageKind: image.kind,
            targetKind: proposal.targetKind
        )
    }
}
