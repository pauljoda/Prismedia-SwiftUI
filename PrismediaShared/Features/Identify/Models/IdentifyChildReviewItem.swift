import Foundation

#if os(iOS) || os(macOS)
    struct IdentifyChildReviewItem: Identifiable, Hashable, Sendable {
        let entity: EntityThumbnail
        let proposal: AdministrativeEntityMetadataProposal?
        let state: IdentifyChildReviewState

        var id: UUID {
            entity.id
        }
    }
#endif
