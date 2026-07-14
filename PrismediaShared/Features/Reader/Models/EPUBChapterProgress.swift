import Foundation

public struct EPUBChapterProgress: Equatable, Sendable {
    public let chapterTitle: String
    public let pageNumber: Int
    public let pageCount: Int

    public var counterText: String {
        "\(pageNumber) / \(pageCount)"
    }

    public init(
        chapterTitle: String,
        visibleProgression: ClosedRange<Double>
    ) {
        let lowerBound = min(max(visibleProgression.lowerBound, 0), 1)
        let upperBound = min(max(visibleProgression.upperBound, lowerBound), 1)
        let visibleFraction = upperBound - lowerBound
        let pageCount =
            visibleFraction > 0
            ? max(1, Int((1 / visibleFraction).rounded()))
            : 1

        self.chapterTitle = chapterTitle
        self.pageCount = pageCount
        pageNumber = min(Int(lowerBound * Double(pageCount)) + 1, pageCount)
    }
}
