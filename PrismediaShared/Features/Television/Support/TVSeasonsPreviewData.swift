import SwiftUI

#if os(tvOS)

    #if DEBUG
        enum TVSeasonsPreviewData {
            static let seriesID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
            static let seasonID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
            static let episodeID = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
            static let seasonThumbnail = EntityThumbnail(
                id: seasonID,
                kind: .videoSeason,
                title: "Season 1",
                parentEntityID: seriesID,
                sortOrder: 1
            )
            static let episodeThumbnail = EntityThumbnail(
                id: episodeID,
                kind: .video,
                title: "The Signal",
                parentEntityID: seasonID,
                parentKind: .videoSeason,
                sortOrder: 1
            )
            static let series = EntityDetail(
                id: seriesID,
                kind: .videoSeries,
                title: "The Chair Company",
                parentEntityID: nil,
                sortOrder: nil,
                hasSourceMedia: false,
                capabilities: [],
                childrenByKind: [.init(kind: .videoSeason, label: "Seasons", entities: [seasonThumbnail], code: nil)],
                relationships: []
            )
            static let season = EntityDetail(
                id: seasonID,
                kind: .videoSeason,
                title: "Season 1",
                parentEntityID: seriesID,
                sortOrder: 1,
                hasSourceMedia: false,
                capabilities: [],
                childrenByKind: [.init(kind: .video, label: "Episodes", entities: [episodeThumbnail], code: nil)],
                relationships: []
            )
            static let episode = EntityDetail(
                id: episodeID,
                kind: .video,
                title: "The Signal",
                parentEntityID: seasonID,
                sortOrder: 1,
                hasSourceMedia: true,
                capabilities: [],
                childrenByKind: [],
                relationships: []
            )
            static let loader = TVSeasonsPreviewLoader(values: [
                seriesID: series,
                seasonID: season,
                episodeID: episode,
            ])
            static let dependencies = EntityDetailDependencies(
                detailLoader: loader,
                mutator: nil,
                collectionItemsLoader: nil,
                readerService: nil,
                videoPlaybackService: nil,
                onEntityMutated: {}
            )
        }

    #endif
#endif
