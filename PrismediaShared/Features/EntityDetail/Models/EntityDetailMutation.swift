import Foundation

enum EntityDetailMutation: Equatable, Sendable {
    case rating(Int?)
    case favorite(Bool)
    case organized(Bool)
}
