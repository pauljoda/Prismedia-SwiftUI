import Foundation

/// Which sides of a Book alignment row are present: paired, readable only, or audio only.
/// Known members are generated from the backend manifest in `ContractCodes.generated.swift`.
public struct BookAlignmentMatchState: RawRepresentable, Codable, Hashable, Sendable {
    // MARK: - Variables

    public let rawValue: String

    // MARK: - Initializers

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
