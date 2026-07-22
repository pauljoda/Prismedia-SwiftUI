import Foundation

#if DEBUG
    actor PreviewEntityAcquisitionService: EntityAcquisitionServicing {
        private let snapshot: EntityMonitorState
        private let additionalSnapshots: [UUID: EntityMonitorState]
        private let acquisitionDetail: RequestActivityAcquisitionDetail?
        private let loadError: String?

        init(
            snapshot: EntityMonitorState,
            acquisitionDetail: RequestActivityAcquisitionDetail? = nil,
            loadError: String? = nil,
            additionalSnapshots: [UUID: EntityMonitorState] = [:]
        ) {
            self.snapshot = snapshot
            self.additionalSnapshots = additionalSnapshots
            self.acquisitionDetail = acquisitionDetail
            self.loadError = loadError
        }

        func loadState(entityID: UUID) async throws -> EntityMonitorState {
            if let loadError {
                throw PreviewEntityAcquisitionFailure(message: loadError)
            }
            return additionalSnapshots[entityID] ?? snapshot
        }

        func latestAcquisition(entityID _: UUID) async throws -> RequestActivityAcquisitionDetail? {
            acquisitionDetail
        }

        func startMonitor(entityID _: UUID) async throws {}

        func pauseMonitor(id _: UUID) async throws {}

        func resumeMonitor(id _: UUID) async throws {}

        func searchAgain(acquisitionID _: UUID) async throws {}

        func searchForRelease(entityID _: UUID) async throws {}

        func syncContainer(entityID _: UUID) async throws {}

        func searchMissingChildren(entityID _: UUID) async throws -> EntityMissingChildrenSearchResponse {
            EntityMissingChildrenSearchResponse(covered: 3, missing: 1)
        }

        func unmonitor(id _: UUID) async throws -> Bool {
            false
        }
    }
#endif
