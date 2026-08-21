import Foundation

public struct AutoIdentifySelectorKind: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    var displayLabel: String {
        if self == .video { return "Videos" }
        if self == .gallery { return "Galleries" }
        if self == .image { return "Images" }
        if self == .audio { return "Audio" }
        if self == .book { return "Books" }
        if self == .comic { return "Comics" }
        return rawValue
    }
}
