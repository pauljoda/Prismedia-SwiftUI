import SwiftUI

#if DEBUG
    struct SearchHubPreviewDetailLoader: EntityDetailLoading {
        func loadEntity(id: UUID) async throws -> EntityDetail {
            throw URLError(.resourceUnavailable)
        }
    }

#endif
