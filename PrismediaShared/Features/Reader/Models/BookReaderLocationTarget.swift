import Foundation

public struct BookReaderLocationTarget: Equatable, Sendable {
    public let location: String
    public let progression: Double

    public init(location: String, progression: Double) {
        self.location = location
        self.progression = min(max(0, progression), 1)
    }
}
