import Foundation

public struct AcquisitionStatusPresentation: Hashable, Sendable {
    public let label: String
    public let systemImage: String
    public let tone: AcquisitionStatusPresentationTone
}
