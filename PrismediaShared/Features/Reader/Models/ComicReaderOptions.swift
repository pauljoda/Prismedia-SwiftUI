import Foundation

public struct ComicReaderOptions: Hashable, Sendable {
    public var pageMode: ComicPageMode
    public var firstPageIsCover: Bool
    public var singlePageIndexes: Set<Int>

    public init(
        pageMode: ComicPageMode = .automatic,
        firstPageIsCover: Bool = true,
        singlePageIndexes: Set<Int> = []
    ) {
        self.pageMode = pageMode
        self.firstPageIsCover = firstPageIsCover
        self.singlePageIndexes = singlePageIndexes
    }

    /// These options with ``ComicPageMode/automatic`` settled for a reader of
    /// the given shape: two pages when it is wider than tall, one otherwise.
    /// Navigation and spreads read only single and double, so the reader
    /// resolves its options before paging.
    public func resolved(isWide: Bool) -> ComicReaderOptions {
        guard pageMode == .automatic else { return self }
        var options = self
        options.pageMode = isWide ? .double : .single
        return options
    }
}
