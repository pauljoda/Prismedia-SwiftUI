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

        static var downloadingDetail: RequestActivityAcquisitionDetail {
            detail(status: "downloading", statusMessage: "Fetching release")
        }

        static var releasesDetail: RequestActivityAcquisitionDetail {
            detail(status: "awaiting-selection", statusMessage: nil)
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
