import Foundation

public enum MusicEntityProjection {
    public static func tracks(in detail: EntityDetail, artist: String? = nil) -> [MusicTrack] {
        let projectedArtist =
            artist
            ?? detail.relationships.first { $0.kind == .musicArtist || $0.kind == .person }?.entities.first?.title
        let artwork = detail.capabilities.compactMap { capability -> EntityImagesCapability? in
            guard case .images(let images) = capability else { return nil }
            return images
        }.first.flatMap { images in
            images.items.first { ["cover", "poster", "thumbnail"].contains($0.kind) }?.path ?? images.coverURL ?? images
                .thumbnail2xURL ?? images.thumbnailURL
        }
        return (detail.childrenByKind + detail.relationships).flatMap(\.entities)
            .filter { ($0.kind == .audioTrack || $0.kind == .audio) && !$0.isWanted }
            .map { MusicTrack(thumbnail: $0, album: detail.title, artist: projectedArtist, artworkPath: artwork) }
            .sorted { ($0.discNumber ?? 0, $0.sortOrder) < ($1.discNumber ?? 0, $1.sortOrder) }
    }

    public static func libraryTracks(
        _ tracks: [EntityThumbnail], albumsByID: [UUID: EntityThumbnail], artistsByID: [UUID: EntityThumbnail]
    ) -> [MusicTrack] {
        tracks.filter { !$0.isWanted }.map { track in
            let album = track.parentEntityID.flatMap { albumsByID[$0] }
            let artist = album?.parentEntityID.flatMap { artistsByID[$0] }
            return MusicTrack(
                thumbnail: track, album: album?.title, artist: artist?.title, artworkPath: album?.bestCoverPath)
        }
    }
}
