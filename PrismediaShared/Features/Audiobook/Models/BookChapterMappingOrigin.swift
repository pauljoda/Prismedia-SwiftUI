import Foundation

/// Who paired a readable chapter with an audio chapter: the user (manual) or the server's matcher (auto).
/// Known members are generated from the backend manifest in `ContractCodes.generated.swift`.
public struct BookChapterMappingOrigin: RawRepresentable, Codable, Hashable, Sendable {
    // MARK: - Variables

    public let rawValue: String

    // MARK: - Initializers

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
