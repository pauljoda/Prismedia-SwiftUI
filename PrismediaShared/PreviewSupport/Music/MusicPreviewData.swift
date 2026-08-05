#if DEBUG
    import Foundation

    @MainActor
    enum MusicPreviewData {
        static let tracks = [
            MusicTrack(
                id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1")!,
                title: "Let It Be",
                artist: "The Beatles",
                artistID: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
                album: "1",
                albumID: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
                duration: 243,
                trackNumber: 1
            ),
            MusicTrack(
                id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2")!,
                title: "Come Together",
                artist: "The Beatles",
                artistID: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
                album: "1",
                albumID: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
                duration: 259,
                trackNumber: 2
            ),
        ]

        static let audiobookTracks = [
            MusicTrack(
                id: UUID(uuidString: "dddddddd-dddd-dddd-dddd-ddddddddddd1")!,
                title: "Part Two",
                artist: "Mara Vale",
                album: "The Glass Archive",
                duration: 3_420,
                trackNumber: 2
            )
        ]

        static func controller(playing: Bool = true) -> MusicPlayerController {
            let controller = MusicPlayerController(
                engine: PreviewAudioPlaybackEngine(),
                service: PreviewMusicPlaybackService()
            )
            if playing { controller.play(tracks: tracks) }
            return controller
        }

        static func audiobookController(playing: Bool = true) -> MusicPlayerController {
            let controller = MusicPlayerController(
                engine: PreviewAudioPlaybackEngine(),
                service: PreviewMusicPlaybackService()
            )
            if playing {
                controller.play(
                    tracks: audiobookTracks,
                    context: MusicPlaybackContext(
                        playbackOwnerEntityID: UUID(uuidString: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee"),
                        playbackOwnerTitle: "The Glass Archive",
                        playbackOwnerEntityKind: .book
                    )
                )
            }
            return controller
        }
    }
#endif
