import Foundation

struct EntityDetailEditPresentation: Identifiable, Hashable, Sendable {
    let detail: EntityDetail
    let initialSection: EntityDetailEditSection

    init(detail: EntityDetail, initialSection: EntityDetailEditSection = .main) {
        self.detail = detail
        self.initialSection = initialSection
    }

    var id: String { "\(detail.id.uuidString):\(initialSection.rawValue)" }
}
