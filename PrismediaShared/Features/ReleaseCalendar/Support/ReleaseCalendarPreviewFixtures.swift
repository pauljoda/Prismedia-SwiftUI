import Foundation

#if DEBUG
    enum ReleaseCalendarPreviewFixtures {
        static let day = ReleaseCalendarDatePolicy.date(from: "2026-08-14")!
        static let events: [ReleaseCalendarEvent] = (1...6).map { index in
            ReleaseCalendarEvent(
                entityID: UUID(),
                monitorID: UUID(),
                kind: .video,
                title: "Episode \(index)",
                parentEntityID: UUID(),
                parentKind: .videoSeries,
                parentTitle: "Example Series",
                dateType: index.isMultiple(of: 2) ? .streamingRelease : .air,
                value: "2026-08-14",
                date: "2026-08-14",
                precision: .day,
                acquisitionStatus: AcquisitionStatus(rawValue: "waiting-for-release"),
                isSearchGate: index == 1,
                searchNotBefore: index == 1 ? "2026-08-16" : nil,
                isSearchEligible: false
            )
        }
    }
#endif
