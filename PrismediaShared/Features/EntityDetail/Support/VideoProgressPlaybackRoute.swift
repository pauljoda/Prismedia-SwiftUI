enum VideoProgressPlaybackRoute {
    static func link(for episode: EntityDetail) -> EntityLink? {
        guard episode.kind == .video else { return nil }

        let images: EntityImagesCapability? = episode.capability()
        let playback: EntityPlaybackCapability? = episode.capability()
        let thumbnail = EntityThumbnail(
            id: episode.id,
            kind: episode.kind,
            title: episode.title,
            parentEntityID: episode.parentEntityID,
            parentKind: episode.parentEntityID == nil ? nil : .videoSeason,
            sortOrder: episode.sortOrder,
            coverURL: images?.coverURL,
            coverThumbURL: images?.thumbnailURL,
            coverThumb2xURL: images?.thumbnail2xURL,
            hasSourceMedia: episode.hasSourceMedia,
            resumeSeconds: playback?.resumeSeconds,
            playCount: playback?.playCount
        )

        return EntityLink(thumbnail: thumbnail, intent: .playback)
    }
}
