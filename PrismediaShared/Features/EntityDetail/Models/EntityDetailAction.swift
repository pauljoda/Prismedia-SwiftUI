import SwiftUI

struct EntityDetailAction: Identifiable, Hashable, Sendable {
    let id: EntityDetailActionID
    let title: String
    let systemImage: String
    let isSelected: Bool
    let isPrimary: Bool
}
