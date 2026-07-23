import Foundation

enum EntityAcquisitionPanelSection: String, Identifiable, Sendable {
    case parentAcquisition
    case childMonitoring
    case childActivity

    var id: String { rawValue }

    static func ordered(demotesFailedParent: Bool) -> [Self] {
        demotesFailedParent
            ? [.childMonitoring, .childActivity, .parentAcquisition]
            : [.parentAcquisition, .childMonitoring, .childActivity]
    }
}
