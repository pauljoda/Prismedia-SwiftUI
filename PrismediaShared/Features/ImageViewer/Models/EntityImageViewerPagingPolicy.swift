import Foundation

public struct EntityImageViewerPagingPolicy: Equatable, Sendable {
    public let preloadDistance: Int

    public init(preloadDistance: Int = 2) {
        precondition(preloadDistance >= 0, "The image paging preload distance must not be negative.")
        self.preloadDistance = preloadDistance
    }

    public func shouldLoadNextPage(
        activeEntityID: UUID?,
        sequence: EntityMediaSequence
    ) -> Bool {
        guard sequence.nextPageRequest != nil,
            let activeEntityID,
            let activeIndex = sequence.index(of: activeEntityID)
        else { return false }
        return sequence.items.distance(from: activeIndex, to: sequence.items.endIndex) - 1
            <= preloadDistance
    }
}
