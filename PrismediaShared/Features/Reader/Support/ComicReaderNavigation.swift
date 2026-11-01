import Foundation

public enum ComicReaderNavigation {
    /// Where a tap lands: thirds on a single page. On a two-page spread the
    /// outer half of each page turns and the inner halves show the controls, so
    /// the controls are reachable away from iPhone Duo's fold.
    public static func tapZone(x: CGFloat, width: CGFloat, showsSpread: Bool = false) -> ComicTapZone {
        guard width > 0 else { return .controls }
        let ratio = x / width
        let turnShare: CGFloat = showsSpread ? 1 / 4 : 1 / 3
        if ratio < turnShare { return .previous }
        if ratio > 1 - turnShare { return .next }
        return .controls
    }

    public static func spread(index: Int, total: Int, options: ComicReaderOptions) -> [Int] {
        guard total > 0 else { return [] }
        let current = clamp(index, total: total)
        guard options.pageMode == .double else { return [current] }
        var cursor = 0
        while cursor < total {
            let next = cursor + 1
            let standsAlone =
                (options.firstPageIsCover && cursor == 0)
                || options.singlePageIndexes.contains(cursor)
                || next >= total
                || options.singlePageIndexes.contains(next)
            let spread = standsAlone ? [cursor] : [cursor, next]
            if spread.contains(current) { return spread }
            cursor += spread.count
        }
        return [current]
    }

    /// The pages a spread lays out from left to right in reading order, where
    /// `nil` is a blank side. A lone page in a two-page layout keeps to its own
    /// side of the gutter, the cover on the right and any later page on the left,
    /// as in a printed book, so it never lies across iPhone Duo's fold; a
    /// double-page image still spans both sides.
    public static func spreadSlots(
        index: Int,
        total: Int,
        options: ComicReaderOptions,
        isDoublePage: (Int) -> Bool
    ) -> [Int?] {
        let pages = spread(index: index, total: total, options: options)
        guard options.pageMode == .double, pages.count == 1, let page = pages.first, !isDoublePage(page)
        else { return pages }
        return page == 0 ? [nil, page] : [page, nil]
    }

    public static func nextIndex(from index: Int, total: Int, options: ComicReaderOptions) -> Int {
        guard total > 0 else { return 0 }
        guard options.pageMode == .double else { return clamp(index + 1, total: total) }
        return clamp((spread(index: index, total: total, options: options).last ?? index) + 1, total: total)
    }

    public static func previousIndex(from index: Int, total: Int, options: ComicReaderOptions) -> Int {
        guard total > 0 else { return 0 }
        guard options.pageMode == .double else { return clamp(index - 1, total: total) }
        let previous = (spread(index: index, total: total, options: options).first ?? index) - 1
        if options.firstPageIsCover, previous <= 0 { return 0 }
        if options.firstPageIsCover {
            return previous.isMultiple(of: 2) ? clamp(previous - 1, total: total) : clamp(previous, total: total)
        }
        return previous.isMultiple(of: 2) ? clamp(previous, total: total) : clamp(previous - 1, total: total)
    }

    public static func gesture(deltaX: CGFloat, deltaY: CGFloat) -> ComicReaderGesture {
        let horizontal = abs(deltaX)
        let vertical = abs(deltaY)
        if ReaderDismissGesture.shouldDismiss(deltaX: deltaX, deltaY: deltaY) {
            return .dismiss
        }
        guard horizontal > 50 else { return .none }
        if horizontal > vertical * 1.3 { return deltaX < 0 ? .next : .previous }
        return .none
    }

    public static func preloadIndexes(
        index: Int,
        total: Int,
        options: ComicReaderOptions,
        radius: Int = 2
    ) -> [Int] {
        let visible = spread(index: index, total: total, options: options)
        guard let first = visible.first, let last = visible.last else { return [] }
        let visibleSet = Set(visible)
        let lower = max(0, first - max(0, radius))
        let upper = min(total - 1, last + max(0, radius))
        return (lower...upper).filter { !visibleSet.contains($0) }
    }

    private static func clamp(_ index: Int, total: Int) -> Int {
        max(0, min(total - 1, index))
    }
}
