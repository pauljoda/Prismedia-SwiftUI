import Foundation

/// Why the server could not align a Book position with the other modality.
/// Known members are generated from the backend manifest in `ContractCodes.generated.swift`.
public struct BookAlignmentGapReason: RawRepresentable, Codable, Hashable, Sendable {
    // MARK: - Variables

    public let rawValue: String

    // MARK: - Initializers

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
