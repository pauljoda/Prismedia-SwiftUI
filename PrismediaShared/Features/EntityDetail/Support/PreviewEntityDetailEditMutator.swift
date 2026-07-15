#if DEBUG
    import Foundation

    actor PreviewEntityDetailEditMutator: EntityMetadataMutating, EntityDetailMutating {
        let detail: EntityDetail

        init(detail: EntityDetail) {
            self.detail = detail
        }

        func updateMetadata(
            id: UUID,
            kind: EntityKind,
            request: EntityDetailMetadataUpdateRequest
        ) async throws -> EntityDetail {
            detail
        }

        func updateRating(id: UUID, value: Int?) async throws -> EntityDetail {
            detail
        }

        func updateFlags(
            id: UUID,
            isFavorite: Bool?,
            isNsfw: Bool?,
            isOrganized: Bool?
        ) async throws -> EntityDetail {
            detail
        }
    }
#endif
