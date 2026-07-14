#if DEBUG
    import Foundation

    struct VideoPlaybackPreviewService: VideoPlaybackServicing {
        func negotiateVideoPlayback(videoID: UUID, forceTranscode: Bool) async throws -> VideoPlaybackPlan {
            VideoPlaybackPlan(
                videoID: videoID,
                url: URL(string: "https://example.invalid/video.mp4")!,
                delivery: forceTranscode ? .transcode : .direct,
                playSessionID: "preview",
                mediaSourceID: "preview",
                durationSeconds: 7_200
            )
        }

        func mediaData(for path: String) async throws -> Data { Data() }
        func authenticatedMediaURL(for path: String) -> URL? { URL(string: path) }
    }
#endif
