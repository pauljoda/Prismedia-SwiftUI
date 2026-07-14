import Foundation

public enum PlayableVideoResolver {
    public static func videoID(
        in detail: EntityDetail,
        sourceThumbnail: EntityThumbnail?
    ) -> UUID? {
        if let sourceThumbnail,
            sourceThumbnail.kind == .video,
            sourceBelongsToDetail(sourceThumbnail, detail: detail)
        {
            return sourceThumbnail.id
        }
        return videoID(in: detail)
    }

    public static func videoID(in detail: EntityDetail) -> UUID? {
        if detail.kind == .video { return detail.id }
        guard detail.kind == .movie else { return nil }
        return detail.childrenByKind
            .first(where: { $0.kind == .video })?
            .entities.first?.id
    }

    private static func sourceBelongsToDetail(
        _ source: EntityThumbnail,
        detail: EntityDetail
    ) -> Bool {
        source.id == detail.id || source.parentEntityID == detail.id
    }
}
