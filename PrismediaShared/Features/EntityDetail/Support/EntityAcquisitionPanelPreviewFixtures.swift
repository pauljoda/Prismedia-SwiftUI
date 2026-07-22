import Foundation

#if DEBUG
    /// In-memory fixtures for the entity acquisition panel previews: monitor states,
    /// acquisition details, and a scenario-driven request-activity preview service.
    enum EntityAcquisitionPanelPreviewFixtures {
        static let entityID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        static let monitorID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        static let acquisitionID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        static let referenceDate = Date(timeIntervalSince1970: 1_783_792_800)

        static var downloadingState: EntityMonitorState {
            EntityMonitorState(
                entityID: entityID,
                canMonitor: true,
                canRequest: true,
                trackableProviders: ["Open Library"],
                discoversChildren: false,
                canSearchMissingChildren: false,
                missingChildEntityKind: nil,
                monitor: monitor(acquisitionStatus: "downloading"),
                latestAcquisition: acquisitionSummary(status: "downloading", progress: 0.64)
            )
        }

        static var awaitingSelectionState: EntityMonitorState {
            EntityMonitorState(
                entityID: entityID,
                canMonitor: true,
                canRequest: true,
                trackableProviders: ["Open Library"],
                discoversChildren: false,
                canSearchMissingChildren: false,
                missingChildEntityKind: nil,
                monitor: monitor(acquisitionStatus: "awaiting-selection"),
                latestAcquisition: acquisitionSummary(status: "awaiting-selection", progress: nil)
            )
        }

        static var wantedState: EntityMonitorState {
            EntityMonitorState(
                entityID: entityID,
                canMonitor: true,
                canRequest: true,
                trackableProviders: ["Open Library"],
                discoversChildren: false,
                canSearchMissingChildren: false,
                missingChildEntityKind: nil,
                monitor: nil,
                latestAcquisition: nil
            )
        }

        static var activeLeafState: EntityMonitorState {
            monitorState(entityID: entityID, status: .active)
        }

        static var groupingState: EntityMonitorState {
            monitorState(
                entityID: entityID,
                status: .active,
                kind: .videoSeason,
                title: "Season 15",
                discoversChildren: true,
                canSearchMissingChildren: true,
                missingChildEntityKind: .video
            )
        }

        static var pausedState: EntityMonitorState {
            monitorState(entityID: entityID, status: .paused)
        }

        static var fulfilledState: EntityMonitorState {
            monitorState(entityID: entityID, status: .fulfilled)
        }

        static var deletingFilesState: EntityMonitorState {
            monitorState(entityID: entityID, status: .deletingFiles)
        }

        static var unavailableState: EntityMonitorState {
            EntityMonitorState(
                entityID: entityID,
                canMonitor: false,
                canRequest: false,
                trackableProviders: [],
                discoversChildren: false,
                canSearchMissingChildren: false,
                missingChildEntityKind: nil,
                monitor: nil,
                latestAcquisition: nil
            )
        }

        static var stoppingState: EntityMonitorState {
            monitorState(entityID: entityID, status: .stopping)
        }

        static var unknownState: EntityMonitorState {
            monitorState(
                entityID: entityID,
                status: EntityMonitorStatus(rawValue: "future-state")
            )
        }

        static var childGroup: EntityGroup {
            EntityGroup(
                kind: .video,
                label: "Episodes",
                entities: [
                    EntityThumbnail(
                        id: childOneID,
                        kind: .video,
                        title: "Failure to Hard Launch",
                        isWanted: true
                    ),
                    EntityThumbnail(
                        id: childTwoID,
                        kind: .video,
                        title: "The Maharelle Sisters",
                        isWanted: true
                    ),
                ],
                code: "episodes"
            )
        }

        static var childStates: [UUID: EntityMonitorState] {
            [
                childOneID: monitorState(entityID: childOneID, status: .active),
                childTwoID: monitorState(entityID: childTwoID, status: .paused),
            ]
        }

        static var childReviewItems: [EntityChildMonitoringItem] {
            [
                childItem(
                    id: childOffID,
                    title: "Unaired Special",
                    state: monitorAvailableState(entityID: childOffID)
                ),
                childItem(
                    id: childActiveID,
                    title: "Failure to Hard Launch",
                    state: monitorState(entityID: childActiveID, status: .active)
                ),
                childItem(
                    id: childPausedID,
                    title: "The Maharelle Sisters",
                    state: monitorState(entityID: childPausedID, status: .paused)
                ),
                childItem(
                    id: childFulfilledID,
                    title: "Serves Me Right for Giving General George S. Patton the Bathroom Key",
                    state: monitorState(entityID: childFulfilledID, status: .fulfilled)
                ),
                childItem(
                    id: childDeletingID,
                    title: "The Petriot Act",
                    state: monitorState(entityID: childDeletingID, status: .deletingFiles)
                ),
                childItem(
                    id: childStoppingID,
                    title: "The Honeymooners",
                    state: monitorState(entityID: childStoppingID, status: .stopping)
                ),
                childItem(
                    id: childUnavailableID,
                    title: "Returning Japanese",
                    state: monitorUnavailableState(entityID: childUnavailableID)
                ),
                childItem(
                    id: childUnknownID,
                    title: "Death Picks Cotton",
                    state: monitorState(
                        entityID: childUnknownID,
                        status: EntityMonitorStatus(rawValue: "future-state")
                    )
                ),
                childItem(
                    id: childBusyID,
                    title: "Raise the Steaks",
                    state: monitorAvailableState(entityID: childBusyID)
                ),
            ]
        }

        static let childBusyID = UUID(uuidString: "00000000-0000-0000-0000-000000000009")!

        static var downloadingDetail: RequestActivityAcquisitionDetail {
            detail(status: "downloading", statusMessage: "Fetching release")
        }

        static var releasesDetail: RequestActivityAcquisitionDetail {
            detail(status: "awaiting-selection", statusMessage: nil)
        }

        static func lifecycleDetail(
            status: String,
            statusMessage: String? = nil,
            hasResumableImport: Bool = false,
            progress: Double? = nil
        ) -> RequestActivityAcquisitionDetail {
            let encodedMessage = statusMessage.map { "\"statusMessage\":\"\($0)\"," } ?? ""
            let encodedProgress = progress.map { "\"progress\":\($0)," } ?? ""
            let json = """
                {
                  "summary":{
                    "id":"\(acquisitionID.uuidString.lowercased())",
                    "status":"\(status)",
                    \(encodedMessage)
                    \(encodedProgress)
                    "title":"Dune",
                    "author":"Frank Herbert",
                    "kind":"book",
                    "createdAt":"2026-07-11T10:00:00Z",
                    "updatedAt":"2026-07-11T12:00:00Z",
                    "entityId":"\(entityID.uuidString.lowercased())",
                    "hasResumableImport":\(hasResumableImport)
                  },
                  "candidates":[]
                }
                """
            return try! PrismediaJSON.decoder()
                .decode(RequestActivityAcquisitionDetail.self, from: Data(json.utf8))
        }

        static func requestActivityService(
            scenario: RequestActivityPreviewScenario
        ) -> any RequestActivityServicing {
            PreviewRequestActivityService(scenario: scenario)
        }

        private static func monitor(acquisitionStatus: String) -> EntityMonitor {
            EntityMonitor(
                id: monitorID,
                kind: .book,
                acquisitionID: acquisitionID,
                status: .active,
                title: "Dune",
                author: "Frank Herbert",
                acquisitionStatus: AcquisitionStatus(rawValue: acquisitionStatus),
                createdAt: referenceDate,
                updatedAt: referenceDate,
                entityID: entityID,
                preset: "all"
            )
        }

        private static let childOneID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        private static let childTwoID = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        private static let childOffID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        private static let childActiveID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        private static let childPausedID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        private static let childFulfilledID = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
        private static let childDeletingID = UUID(uuidString: "00000000-0000-0000-0000-000000000005")!
        private static let childStoppingID = UUID(uuidString: "00000000-0000-0000-0000-000000000006")!
        private static let childUnavailableID = UUID(uuidString: "00000000-0000-0000-0000-000000000007")!
        private static let childUnknownID = UUID(uuidString: "00000000-0000-0000-0000-000000000008")!

        private static func childItem(
            id: UUID,
            title: String,
            state: EntityMonitorState
        ) -> EntityChildMonitoringItem {
            EntityChildMonitoringItem(
                entity: EntityThumbnail(
                    id: id,
                    kind: .video,
                    title: title,
                    isWanted: true
                ),
                state: state
            )
        }

        private static func monitorAvailableState(entityID: UUID) -> EntityMonitorState {
            EntityMonitorState(
                entityID: entityID,
                canMonitor: true,
                canRequest: true,
                trackableProviders: ["TMDB"],
                discoversChildren: false,
                canSearchMissingChildren: false,
                missingChildEntityKind: nil,
                monitor: nil,
                latestAcquisition: nil
            )
        }

        private static func monitorUnavailableState(entityID: UUID) -> EntityMonitorState {
            EntityMonitorState(
                entityID: entityID,
                canMonitor: false,
                canRequest: false,
                trackableProviders: [],
                discoversChildren: false,
                canSearchMissingChildren: false,
                missingChildEntityKind: nil,
                monitor: nil,
                latestAcquisition: nil
            )
        }

        private static func monitorState(
            entityID: UUID,
            status: EntityMonitorStatus,
            kind: EntityKind = .book,
            title: String = "Dune",
            discoversChildren: Bool = false,
            canSearchMissingChildren: Bool = false,
            missingChildEntityKind: EntityKind? = nil
        ) -> EntityMonitorState {
            EntityMonitorState(
                entityID: entityID,
                canMonitor: true,
                canRequest: true,
                trackableProviders: [discoversChildren ? "TMDB" : "Open Library"],
                discoversChildren: discoversChildren,
                canSearchMissingChildren: canSearchMissingChildren,
                missingChildEntityKind: missingChildEntityKind,
                monitor: EntityMonitor(
                    id: monitorID,
                    kind: kind,
                    acquisitionID: nil,
                    status: status,
                    title: title,
                    author: nil,
                    acquisitionStatus: nil,
                    createdAt: referenceDate,
                    updatedAt: referenceDate,
                    entityID: entityID,
                    preset: "all"
                ),
                latestAcquisition: nil
            )
        }

        private static func acquisitionSummary(
            status: String,
            progress: Double?
        ) -> EntityAcquisitionSummary {
            EntityAcquisitionSummary(
                id: acquisitionID,
                status: AcquisitionStatus(rawValue: status),
                statusMessage: nil,
                title: "Dune",
                author: "Frank Herbert",
                progress: progress,
                createdAt: referenceDate,
                updatedAt: referenceDate,
                entityID: entityID
            )
        }

        private static func detail(
            status: String,
            statusMessage: String?
        ) -> RequestActivityAcquisitionDetail {
            let message = statusMessage.map { "\"statusMessage\":\"\($0)\"," } ?? ""
            let json = """
                {
                  "summary":{
                    "id":"\(acquisitionID.uuidString.lowercased())",
                    "status":"\(status)",
                    \(message)
                    "title":"Dune",
                    "author":"Frank Herbert",
                    "kind":"book",
                    "createdAt":"2026-07-11T10:00:00Z",
                    "updatedAt":"2026-07-11T12:00:00Z",
                    "entityId":"\(entityID.uuidString.lowercased())"
                  },
                  "candidates":[]
                }
                """
            return try! PrismediaJSON.decoder()
                .decode(RequestActivityAcquisitionDetail.self, from: Data(json.utf8))
        }
    }
#endif
