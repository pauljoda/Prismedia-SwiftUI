import Foundation

struct PDFReaderOutlineItem: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let pageIndex: Int?
    let children: [PDFReaderOutlineItem]?

    init(
        id: String,
        title: String,
        pageIndex: Int?,
        children: [PDFReaderOutlineItem]? = nil
    ) {
        self.id = id
        self.title = title
        self.pageIndex = pageIndex
        self.children = children?.isEmpty == true ? nil : children
    }
}
