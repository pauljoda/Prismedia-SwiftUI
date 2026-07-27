import Foundation

#if DEBUG
    struct PreviewReleaseCalendarLoader: ReleaseCalendarLoading {
        func releases(from _: Date, through _: Date) async throws -> [ReleaseCalendarEvent] {
            ReleaseCalendarPreviewFixtures.events
        }
    }
#endif
