import SwiftUI

#if DEBUG
    struct ComicReaderPreviewService: BookReaderServicing {
        let values: [UUID: EntityDetail]

        func loadEntity(id: UUID) async throws -> EntityDetail {
            guard let value = values[id] else { throw BookReaderManifestError.noReadablePages }
            return value
        }

        func loadPageData(id: UUID) async throws -> Data {
            Data(
                base64Encoded:
                    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScL+WQAAAABJRU5ErkJggg==")
                ?? Data()
        }

        func updateReadingProgress(id: UUID, request: EntityProgressUpdateRequest) async throws {}
    }

#endif
