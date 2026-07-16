import Foundation

struct EntityGridActionConfirmation: Identifiable, Sendable {
    let action: EntityGridSelectionAction
    let title: String
    let message: String
    let isDestructive: Bool

    var id: EntityGridSelectionAction { action }
}
