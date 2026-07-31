import Foundation

/// Generated client snapshot of one Entity kind's manual acquisition policy.
public struct EntityManualAcquisitionPolicy: Hashable, Sendable {
    /// Whether this kind is a concrete browser upload/import unit.
    public let supportsUpload: Bool
    /// Whether existing owned content may be replaced after review.
    public let supportsReplacement: Bool

    public init(supportsUpload: Bool, supportsReplacement: Bool) {
        self.supportsUpload = supportsUpload
        self.supportsReplacement = supportsReplacement
    }
}
