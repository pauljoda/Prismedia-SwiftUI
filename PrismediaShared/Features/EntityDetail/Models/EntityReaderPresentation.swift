import SwiftUI

struct EntityReaderPresentation: Identifiable, Hashable {
    let detail: EntityDetail
    let command: BookReaderCommand
    let initialEPUBLocation: String?
    let initialEPUBProgression: Double?
    let initialEPUBUpdatedAt: Date?
    let companionAudiobookBookID: UUID?
    let companionAudiobookTrackID: UUID?
    let companionAudiobookStartSeconds: Double

    init(
        detail: EntityDetail,
        command: BookReaderCommand,
        initialEPUBLocation: String? = nil,
        initialEPUBProgression: Double? = nil,
        initialEPUBUpdatedAt: Date? = nil,
        companionAudiobookBookID: UUID? = nil,
        companionAudiobookTrackID: UUID? = nil,
        companionAudiobookStartSeconds: Double = 0
    ) {
        self.detail = detail
        self.command = command
        self.initialEPUBLocation = initialEPUBLocation
        self.initialEPUBProgression = initialEPUBProgression
        self.initialEPUBUpdatedAt = initialEPUBUpdatedAt
        self.companionAudiobookBookID = companionAudiobookBookID
        self.companionAudiobookTrackID = companionAudiobookTrackID
        self.companionAudiobookStartSeconds = max(0, companionAudiobookStartSeconds)
    }

    var id: UUID { detail.id }
}
