import Foundation

enum EntityDetailEditSection: String, CaseIterable, Identifiable, Hashable, Sendable {
    case main
    case metadata

    var id: String { rawValue }

    var title: String {
        switch self {
        case .main: "Main"
        case .metadata: "Metadata"
        }
    }

    init?(detailSection: EntityDetailSectionID) {
        switch detailSection {
        case .details: self = .main
        case .metadata: self = .metadata
        default: return nil
        }
    }
}
