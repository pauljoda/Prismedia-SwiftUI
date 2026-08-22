import SwiftUI

#if DEBUG
    struct ComicReaderPreviewService: BookReaderServicing {
        let values: [UUID: EntityDetail]

        func loadEntity(id: UUID) async throws -> EntityDetail {
            guard let value = values[id] else { throw BookReaderManifestError.noReadablePages }
            return value
        }

        func loadEntityReaderManifest(id: UUID) async throws -> EntityReaderManifest {
            guard values[id] != nil else { throw BookReaderManifestError.noReadablePages }
            return EntityReaderManifest(
                entityID: id,
                direction: .leftToRight,
                defaultMode: .paged,
                coverOrdinal: 0,
                pages: [ComicReaderPreviewData.sourcePage]
            )
        }

        func loadEntityReaderPageData(id: UUID, ordinal: Int) async throws -> Data {
            guard values[id] != nil, ordinal == 0 else {
                throw BookReaderManifestError.noReadablePages
            }
            return Data(
                base64Encoded:
                    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScL+WQAAAABJRU5ErkJggg==")
                ?? Data()
        }

        func updateReadingProgress(id: UUID, request: EntityProgressUpdateRequest) async throws {}
    }

#endif
