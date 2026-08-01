import Foundation

public enum PlayableVideoResolver {
    public static func videoID(
        in detail: EntityDetail,
        sourceThumbnail: EntityThumbnail?
    ) -> UUID? {
        if let sourceThumbnail,
            sourceThumbnail.hasSourceMedia,
            sourceThumbnail.kind.definition?.mediaQualityFamily == .video,
            sourceBelongsToDetail(sourceThumbnail, detail: detail)
        {
            return sourceThumbnail.id
        }
        return videoID(in: detail)
    }

    public static func videoID(in detail: EntityDetail) -> UUID? {
        detail.capability(EntityPlayableVideoCapability.self) == nil ? nil : detail.id
    }

    private static func sourceBelongsToDetail(
        _ source: EntityThumbnail,
        detail: EntityDetail
    ) -> Bool {
        source.id == detail.id || source.parentEntityID == detail.id
    }
}
