import Foundation

/// Which way a comic's pages turn, chosen in the reader. Automatic follows the direction
/// the library recorded for the comic; the other choices override it for the whole series,
/// as for a manga scan whose metadata never said it reads right to left.
public enum ComicReadingDirection: String, CaseIterable, Codable, Hashable, Sendable {
    case automatic
    case leftToRight
    case rightToLeft

    /// Whether pages turn from right to left under this choice, for a comic the library
    /// recorded as reading in `recorded`.
    public func readsRightToLeft(recorded: PageReadingDirection) -> Bool {
        switch self {
        case .automatic: recorded == .rightToLeft
        case .leftToRight: false
        case .rightToLeft: true
        }
    }
}
