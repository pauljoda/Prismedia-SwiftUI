import SwiftUI

#if os(tvOS)

    #if DEBUG
        struct TVSeasonsPreviewLoader: EntityDetailLoading {
            let values: [UUID: EntityDetail]

            func loadEntity(id: UUID) async throws -> EntityDetail {
                guard let detail = values[id] else { throw TVSeasonsPreviewError.missing }
                return detail
            }
        }

    #endif
#endif
