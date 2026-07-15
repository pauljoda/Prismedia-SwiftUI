import SwiftUI

struct EntityReaderPresentation: Identifiable, Equatable {
    let detail: EntityDetail
    let command: BookReaderCommand
    let initialEPUBLocation: String?
    let companionAudiobookBookID: UUID?

    init(
        detail: EntityDetail,
        command: BookReaderCommand,
        initialEPUBLocation: String? = nil,
        companionAudiobookBookID: UUID? = nil
    ) {
        self.detail = detail
        self.command = command
        self.initialEPUBLocation = initialEPUBLocation
        self.companionAudiobookBookID = companionAudiobookBookID
    }

    var id: UUID { detail.id }
}
