#if DEBUG
    import Foundation

    struct EntityMediaPreviewLoader: EntityDetailLoading, EntityImageSourceLoading {
        let details: [UUID: EntityDetail]
        var sourceData = EntityMediaPreviewData.pngData
        var failure: Error?
        var delayMilliseconds = 0

        func loadEntity(id: UUID) async throws -> EntityDetail {
            if delayMilliseconds > 0 {
                try await Task.sleep(for: .milliseconds(delayMilliseconds))
            }
            if let failure { throw failure }
            guard let detail = details[id] else { throw URLError(.fileDoesNotExist) }
            return detail
        }

        func loadEntitySourceData(id: UUID) async throws -> Data {
            if delayMilliseconds > 0 {
                try await Task.sleep(for: .milliseconds(delayMilliseconds))
            }
            if let failure { throw failure }
            return sourceData
        }
    }
#endif
