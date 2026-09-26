import Foundation

/// How a Book's audio divides into chapters: embedded chapters, one file per chapter, part or disc
/// splits, or one file without chapter markers.
/// Known members are generated from the backend manifest in `ContractCodes.generated.swift`.
public struct AudiobookStructure: RawRepresentable, Codable, Hashable, Sendable {
    // MARK: - Variables

    public let rawValue: String

    // MARK: - Initializers

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
