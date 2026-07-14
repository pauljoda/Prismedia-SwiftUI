#if os(iOS) || os(macOS)
    import PDFKit

    @MainActor
    struct PDFOutlineBuilder {
        func items(in document: PDFDocument) -> [PDFReaderOutlineItem] {
            guard let root = document.outlineRoot else { return [] }
            return (0..<root.numberOfChildren).compactMap { index in
                root.child(at: index).map { item($0, document: document, path: "\(index)") }
            }
        }

        private func item(
            _ outline: PDFOutline,
            document: PDFDocument,
            path: String
        ) -> PDFReaderOutlineItem {
            let children = (0..<outline.numberOfChildren).compactMap { index in
                outline.child(at: index).map {
                    item($0, document: document, path: "\(path).\(index)")
                }
            }
            let pageIndex = outline.destination?.page.flatMap { page in
                let index = document.index(for: page)
                return document.pageCount > index && index >= 0 ? index : nil
            }
            let candidate = outline.label?.trimmingCharacters(in: .whitespacesAndNewlines)
            let title = if let candidate, !candidate.isEmpty { candidate } else { "Untitled Section" }
            return PDFReaderOutlineItem(
                id: path,
                title: title,
                pageIndex: pageIndex,
                children: children
            )
        }
    }
#endif
