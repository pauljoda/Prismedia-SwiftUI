import Foundation

/// A way of consuming a work that keeps its own exact checkpoint, such as reading or listening to a
/// Book. Known members are generated from the backend manifest in `ContractCodes.generated.swift`;
/// unknown future spellings decode without failing.
public struct ConsumptionModality: RawRepresentable, Codable, Hashable, Sendable {
    // MARK: - Variables

    public let rawValue: String

    // MARK: - Initializers

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
