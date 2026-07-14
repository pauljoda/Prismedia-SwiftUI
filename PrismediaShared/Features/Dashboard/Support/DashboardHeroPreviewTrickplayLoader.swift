#if DEBUG
    import Foundation

        struct DashboardHeroPreviewTrickplayLoader: TrickplayFrameLoading {
            func loadFrames(playlistPath: String) async -> [TrickplayPlaylist.Frame] {
            []
        }
    }
#endif
