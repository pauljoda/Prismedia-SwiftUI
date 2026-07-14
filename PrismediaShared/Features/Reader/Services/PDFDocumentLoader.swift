#if os(iOS) || os(macOS)
    import Foundation
    import PDFKit

    @MainActor
    struct PDFDocumentLoader {
        func load(data: Data) throws -> PDFDocument {
            guard let document = PDFDocument(data: data),
                !document.isLocked,
                document.pageCount > 0
            else {
                throw PDFReaderError.invalidDocument
            }
            return document
        }
    }
#endif
