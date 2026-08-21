import Foundation

public struct ComicReaderOptions: Hashable, Sendable {
    public var pageMode: ComicPageMode
    public var firstPageIsCover: Bool
    public var singlePageIndexes: Set<Int>

    public init(
        pageMode: ComicPageMode = .single,
        firstPageIsCover: Bool = true,
        singlePageIndexes: Set<Int> = []
    ) {
        self.pageMode = pageMode
        self.firstPageIsCover = firstPageIsCover
        self.singlePageIndexes = singlePageIndexes
    }
}
