#if os(iOS) || os(macOS)
    import Foundation
    import PDFKit

    @MainActor
    struct PDFTextSearchService {
        func matches(in document: PDFDocument, query: String) async -> [PDFSelection] {
            let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else { return [] }
            return await PDFTextSearchCoordinator().search(in: document, query: query).values
        }
    }
#endif
