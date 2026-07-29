import Foundation

/// A stable source-resource range in the cross-platform, whole-book EPUB fraction.
public struct EPUBReadingProgressRange: Equatable, Hashable, Sendable {
    public let location: String
    public let startFraction: Double
    public let endFraction: Double

    public init(
        location: String,
        startFraction: Double,
        endFraction: Double
    ) {
        self.location = location
        self.startFraction = min(max(0, startFraction), 1)
        self.endFraction = min(max(self.startFraction, endFraction), 1)
    }
}
