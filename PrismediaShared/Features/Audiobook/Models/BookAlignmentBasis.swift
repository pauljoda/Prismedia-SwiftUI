import Foundation

/// How the server derived an aligned Book target: the exact recorded position, a chapter start, an interpolated position, or a fresh start.
/// Known members are generated from the backend manifest in `ContractCodes.generated.swift`.
public struct BookAlignmentBasis: RawRepresentable, Codable, Hashable, Sendable {
    // MARK: - Variables

    public let rawValue: String

    // MARK: - Initializers

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
