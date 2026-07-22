import Foundation

#if DEBUG
    enum EntityChildAcquisitionActivityPreviewFixtures {
        static let parentID = EntityAcquisitionPanelPreviewFixtures.entityID
        static let referenceDate = Date(timeIntervalSince1970: 1_784_131_200)

        static var quietItem: EntityChildAcquisitionActivityItem {
            item(index: 1, title: "Future Episode", status: nil)
        }

        static var preparingItem: EntityChildAcquisitionActivityItem {
            item(index: 2, title: "The Long Way Around", status: nil, preparesMetadata: true)
        }

        static var pendingItem: EntityChildAcquisitionActivityItem {
            item(index: 3, title: "Signals in the Dark", status: "pending")
        }

        static var searchingItem: EntityChildAcquisitionActivityItem {
            item(index: 4, title: "A Place Between Stars", status: "searching")
        }

        static var queuedItem: EntityChildAcquisitionActivityItem {
            item(index: 5, title: "The Quiet Orbit", status: "queued")
        }

        static var awaitingSelectionItem: EntityChildAcquisitionActivityItem {
            item(index: 13, title: "Two Possible Signals", status: "awaiting-selection")
        }

        static var downloadingItem: EntityChildAcquisitionActivityItem {
            item(index: 6, title: "Light Falls Forward", status: "downloading", progress: 0.47)
        }

        static var importingItem: EntityChildAcquisitionActivityItem {
            item(index: 7, title: "The Last Signal", status: "importing", progress: 0.82)
        }

        static var downloadedItem: EntityChildAcquisitionActivityItem {
            item(index: 14, title: "Arrival Confirmed", status: "downloaded", progress: 1)
        }

        static var importedItem: EntityChildAcquisitionActivityItem {
            item(index: 8, title: "Homeward", status: "imported", progress: 1)
        }

        static var failedItem: EntityChildAcquisitionActivityItem {
            item(
                index: 9,
                title: "Beyond the Terminus",
                status: "failed",
                message: "The selected release could not be imported."
            )
        }

        static var manualImportItem: EntityChildAcquisitionActivityItem {
            item(
                index: 10,
                title: "A Map of Ash",
                status: "manual-import-required",
                message: "Choose the matching media file to finish this import."
            )
        }

        static var cancelledItem: EntityChildAcquisitionActivityItem {
            item(index: 11, title: "The Abandoned Moon", status: "cancelled")
        }

        static var unknownItem: EntityChildAcquisitionActivityItem {
            item(index: 12, title: "Uncharted State", status: "future-transition")
        }

        static var simultaneousItems: [EntityChildAcquisitionActivityItem] {
            [
                importedItem,
                downloadingItem,
                failedItem,
                awaitingSelectionItem,
                searchingItem,
                manualImportItem,
                preparingItem,
                queuedItem,
                importingItem,
                downloadedItem,
                cancelledItem,
                unknownItem,
            ]
        }

        static var childGroup: EntityGroup {
            EntityGroup(
                kind: .video,
                label: "Episodes",
                entities: simultaneousItems.map { item in
                    EntityThumbnail(
                        id: item.entity.id,
                        kind: item.entity.kind,
                        title: item.entity.title,
                        parentEntityID: parentID,
                        parentKind: .videoSeason,
                        isWanted: true,
                        latestAcquisitionStatus: item.acquisition?.status
                    )
                },
                code: "episodes"
            )
        }

        static var childStates: [UUID: EntityMonitorState] {
            Dictionary(uniqueKeysWithValues: simultaneousItems.map { ($0.id, $0.state) })
        }

        @MainActor
        static var service: EntityAcquisitionService {
            EntityAcquisitionService(
                port: PreviewEntityAcquisitionService(
                    snapshot: EntityAcquisitionPanelPreviewFixtures.wantedState,
                    additionalSnapshots: childStates
                )
            )
        }

        private static func item(
            index: Int,
            title: String,
            status: String?,
            progress: Double? = nil,
            message: String? = nil,
            preparesMetadata: Bool = false
        ) -> EntityChildAcquisitionActivityItem {
            let entityID = UUID(
                uuidString: String(format: "81000000-0000-0000-0000-%012d", index)
            )!
            let entity = EntityThumbnail(
                id: entityID,
                kind: .video,
                title: title,
                parentEntityID: parentID,
                parentKind: .videoSeason,
                isWanted: true,
                latestAcquisitionStatus: status.map(AcquisitionStatus.init(rawValue:))
            )
            let monitor = preparesMetadata
                ? EntityMonitor(
                    id: UUID(uuidString: "82000000-0000-0000-0000-000000000001")!,
                    kind: .video,
                    acquisitionID: nil,
                    status: .active,
                    title: title,
                    author: nil,
                    acquisitionStatus: nil,
                    createdAt: referenceDate,
                    updatedAt: referenceDate,
                    entityID: entityID,
                    preset: "all"
                )
                : nil
            let acquisition = status.map {
                EntityAcquisitionSummary(
                    id: UUID(
                        uuidString: String(format: "83000000-0000-0000-0000-%012d", index)
                    )!,
                    status: AcquisitionStatus(rawValue: $0),
                    statusMessage: message,
                    title: title,
                    progress: progress,
                    createdAt: referenceDate.addingTimeInterval(-3_600),
                    updatedAt: referenceDate.addingTimeInterval(TimeInterval(index * 60)),
                    kind: .video,
                    entityID: entityID
                )
            }
            return EntityChildAcquisitionActivityItem(
                entity: entity,
                state: EntityMonitorState(
                    entityID: entityID,
                    canMonitor: true,
                    canRequest: true,
                    trackableProviders: ["TMDB"],
                    discoversChildren: false,
                    canSearchMissingChildren: false,
                    missingChildEntityKind: nil,
                    monitor: monitor,
                    latestAcquisition: acquisition
                )
            )
        }
    }
#endif
