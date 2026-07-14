#if os(iOS) || os(macOS)
    import PDFKit

    struct PDFSelectionResults: @unchecked Sendable {
        let values: [PDFSelection]
    }
#endif
