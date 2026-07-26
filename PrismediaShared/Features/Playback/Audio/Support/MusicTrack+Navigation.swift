#if os(iOS) || os(macOS)
    extension MusicTrack {
        var albumNavigationLink: EntityLink? {
            guard let albumID else { return nil }
            return EntityLink(
                entityID: albumID,
                kind: .audioLibrary,
                thumbnailPreview: EntityLinkPreview(
                    title: album ?? "Album",
                    subtitle: artist,
                    artworkPath: artworkPath
                )
            )
        }

        var artistNavigationLink: EntityLink? {
            guard let artistID else { return nil }
            return EntityLink(
                entityID: artistID,
                kind: .musicArtist,
                thumbnailPreview: EntityLinkPreview(
                    title: MusicPresentation.artist(artist),
                    subtitle: nil,
                    artworkPath: artworkPath
                )
            )
        }
    }
#endif
