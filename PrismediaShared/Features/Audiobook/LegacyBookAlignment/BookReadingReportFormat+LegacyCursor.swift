import Foundation

extension BookReadingReportFormat {
    /// Reports for servers before 3.8, which address EPUB positions in ten-thousandths of the
    /// book and keep no modality checkpoints.
    public static let legacyCursor = BookReadingReportFormat(positionTotal: 10_000, modality: nil)
}
