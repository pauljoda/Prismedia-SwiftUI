import Foundation

enum EntityDetailCreditRole: String, CaseIterable, Identifiable, Sendable {
    case person
    case actor
    case director
    case writer
    case producer
    case creator
    case artist
    case narrator
    case composer

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}
