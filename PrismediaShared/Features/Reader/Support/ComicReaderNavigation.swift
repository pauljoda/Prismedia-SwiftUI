import Foundation

public enum ComicReaderNavigation {
    public static func tapZone(x: CGFloat, width: CGFloat) -> ComicTapZone {
        guard width > 0 else { return .controls }
        let ratio = x / width
        if ratio < 1 / 3 { return .previous }
        if ratio > 2 / 3 { return .next }
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
