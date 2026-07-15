import Foundation

enum EntityDetailEditPolicy {
    static func defaultCreditRole(in detail: EntityDetail) -> EntityDetailCreditRole {
        switch detail.kind {
        case .movie, .video, .videoSeries, .videoSeason:
            return .actor
        case .audio, .audioLibrary, .audioTrack, .musicArtist:
            return .artist
        case .bookAuthor:
            return .writer
        default:
            return .person
        }
    }

    static func canEditTags(in detail: EntityDetail) -> Bool {
        ![EntityKind.person, .studio, .tag, .videoSeason].contains(detail.kind)
    }

    static func canEditStudio(in detail: EntityDetail) -> Bool {
        ![EntityKind.collection, .person, .studio, .tag, .videoSeason].contains(detail.kind)
    }

    static func canEditCredits(in detail: EntityDetail) -> Bool {
        ![EntityKind.collection, .person, .studio, .tag, .videoSeason].contains(detail.kind)
    }
}
