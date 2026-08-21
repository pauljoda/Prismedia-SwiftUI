import Foundation

/// Serialized-comic installment classification supplied by the canonical Entity capability.
public struct EntityComicInstallmentMetadataCapability: Decodable, Hashable, Sendable {
    public let installmentKind: ComicInstallmentKind
}
