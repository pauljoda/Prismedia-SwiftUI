import SwiftUI

struct EntityDetailSection: Identifiable, Hashable, Sendable {
    let id: EntityDetailSectionID
    let title: String
    let systemImage: String
    let count: Int?
}
