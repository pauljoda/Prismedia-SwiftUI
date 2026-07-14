import Foundation

#if DEBUG
    actor PreviewEntityAcquisitionService: EntityAcquisitionServicing {
        private let snapshot: EntityMonitorState

        init(snapshot: EntityMonitorState) {
            self.snapshot = snapshot
        }

        func loadState(entityID _: UUID) async throws -> EntityMonitorState {
            snapshot
        }

        func startMonitor(entityID _: UUID) async throws {}

        func pauseMonitor(id _: UUID) async throws {}

        func resumeMonitor(id _: UUID) async throws {}

        func searchAgain(acquisitionID _: UUID) async throws {}

        func unmonitor(id _: UUID) async throws -> Bool {
            false
        }
    }
#endif
