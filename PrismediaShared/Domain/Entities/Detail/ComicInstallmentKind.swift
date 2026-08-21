import Foundation

/// Forward-compatible serialized-comic installment classification.
public struct ComicInstallmentKind: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
