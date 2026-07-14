import Foundation

public struct ComicReaderOptions: Hashable, Sendable {
    public var pageMode: ComicPageMode
    public var firstPageIsCover: Bool

    public init(pageMode: ComicPageMode = .single, firstPageIsCover: Bool = true) {
        self.pageMode = pageMode
        self.firstPageIsCover = firstPageIsCover
    }
}
