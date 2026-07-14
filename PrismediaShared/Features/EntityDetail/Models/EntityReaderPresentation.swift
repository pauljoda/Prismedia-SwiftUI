import SwiftUI

struct EntityReaderPresentation: Identifiable, Equatable {
    let detail: EntityDetail
    let command: BookReaderCommand
    var id: UUID { detail.id }
}
