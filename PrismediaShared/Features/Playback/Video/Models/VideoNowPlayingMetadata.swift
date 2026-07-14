import Foundation

struct VideoNowPlayingMetadata: Equatable, Sendable {
    let contentID: UUID
    let title: String
    let subtitle: String?
    let artworkPath: String?

    init(
        detail: EntityDetail,
        ownerLink: EntityLink,
        playableDetail: EntityDetail? = nil
    ) {
        contentID = ownerLink.entityID
        title = detail.title
        subtitle = ownerLink.thumbnailPreview?.subtitle
        artworkPath =
            Self.posterPath(in: detail)
            ?? ownerLink.thumbnailPreview?.artworkPath
            ?? playableDetail.flatMap(Self.posterPath)
    }

    private static func posterPath(in detail: EntityDetail) -> String? {
        let images = detail.capabilities.compactMap { capability -> EntityImagesCapability? in
            guard case .images(let images) = capability else { return nil }
            return images
        }.first
        let posterKinds = ["poster", "thumbnail", "cover", "logo"]
        return images?.items.first { posterKinds.contains($0.kind) }?.path
            ?? images?.coverURL
            ?? images?.thumbnail2xURL
            ?? images?.thumbnailURL
    }
}
