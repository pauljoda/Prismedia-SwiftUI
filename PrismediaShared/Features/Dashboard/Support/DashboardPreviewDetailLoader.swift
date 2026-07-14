import SwiftUI

#if DEBUG
    struct DashboardPreviewDetailLoader: EntityDetailLoading {
        func loadEntity(id: UUID) async throws -> EntityDetail {
            throw URLError(.resourceUnavailable)
        }
    }

#endif
