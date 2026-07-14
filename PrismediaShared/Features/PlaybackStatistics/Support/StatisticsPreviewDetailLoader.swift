import SwiftUI

#if DEBUG
    struct StatisticsPreviewDetailLoader: EntityDetailLoading {
        func loadEntity(id: UUID) async throws -> EntityDetail {
            throw URLError(.resourceUnavailable)
        }
    }

#endif
