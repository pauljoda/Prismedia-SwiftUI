import Foundation

/// How a reader addresses its progress reports for one work on the connected server: the total
/// whole-book EPUB positions are expressed in, and the modality each report names.
public struct BookReadingReportFormat: Equatable, Hashable, Sendable {
    // MARK: - Variables

    /// Total of whole-book EPUB positions; `cfi` reports use it as their total. Servers from 3.8
    /// publish it as the alignment's `readablePositionTotal`.
    public let positionTotal: Int
    /// Modality named on each report, for kinds that keep modality checkpoints.
    public let modality: ConsumptionModality?

    // MARK: - Initializers

    public init(positionTotal: Int, modality: ConsumptionModality?) {
        self.positionTotal = max(1, positionTotal)
        self.modality = modality
    }

    /// Reading reports for a work of `kind`: the server's readable position total when its
    /// alignment is loaded, and the reading modality when the kind keeps a reading checkpoint.
    /// Servers that predate modality checkpoints ignore the modality.
    init(kind: EntityKind, alignment: BookAlignmentResponse?) {
        self.init(
            positionTotal: alignment?.readablePositionTotal ?? Self.legacyCursor.positionTotal,
            modality: kind.definition?.modalities.contains(.reading) == true ? .reading : nil
        )
    }
}
