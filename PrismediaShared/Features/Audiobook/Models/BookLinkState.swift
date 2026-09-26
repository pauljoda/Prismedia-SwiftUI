import Foundation

/// Whether a Book's reading and listening move together. A Linked Book switches between formats
/// inside exactly paired chapters and keeps one progress; a Separate Book keeps two.
/// Known members are generated from the backend manifest in `ContractCodes.generated.swift`.
public struct BookLinkState: RawRepresentable, Codable, Hashable, Sendable {
    // MARK: - Variables

    public let rawValue: String

    // MARK: - Initializers

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
