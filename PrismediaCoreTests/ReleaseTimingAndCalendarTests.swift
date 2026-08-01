import XCTest

@testable import PrismediaCore

final class ReleaseTimingAndCalendarTests: XCTestCase {
    func testWaitingAndLegacyManualSearchStatusesShareReleaseLifecycle() {
        for statusValue in ["waiting-for-release", "manual-search-required"] {
            let status = AcquisitionStatus(rawValue: statusValue)
            XCTAssertEqual(RequestActivityStatusPolicy.label(for: status), "Waiting for release")
            XCTAssertEqual(RequestActivityStatusPolicy.systemImage(for: status), "calendar.badge.clock")
            XCTAssertEqual(
                RequestActivityAcquisitionLifecyclePolicy.description(
                    for: status,
                    message: "Manual search required"
                ),
                "Searching will begin when the configured release milestone is reached."
            )
            XCTAssertEqual(
                RequestActivityAcquisitionLifecyclePolicy.primaryAction(
                    for: status,
                    hasResumableImport: false
                ),
                .research
            )
            XCTAssertFalse(
                RequestActivityAcquisitionLifecyclePolicy.showsReleasePicker(
                    for: status,
                    hasResumableImport: false
                )
            )
        }
    }

    func testManualDatePromptAppearsOnlyAfterCompletedLookupReportsNoMilestone() {
        XCTAssertFalse(ReleaseDatePromptPolicy.offersManualEntry(metadataUnavailable: false))
        XCTAssertTrue(ReleaseDatePromptPolicy.offersManualEntry(metadataUnavailable: true))
    }

    func testEntityDatesUseMeaningfulMilestoneOrderAndPreserveUnknownDates() {
        let dates = [
            EntityDate(code: "custom-festival", value: "2026-01"),
            EntityDate(code: EntityDateType.physicalRelease.rawValue, value: "2026-09-01"),
            EntityDate(code: EntityDateType.premiere.rawValue, value: "2026-04-02"),
            EntityDate(code: EntityDateType.streamingRelease.rawValue, value: "2026-07-12"),
        ]

        XCTAssertEqual(
            EntityDateMilestonePolicy.sorted(dates).map(\.code),
            ["premiere", "streaming-release", "physical-release", "custom-festival"]
        )
    }

    func testEntityDetailPresentsEveryTypedReleaseMilestone() {
        let detail = EntityDetail(
            id: UUID(),
            kind: .movie,
            title: "Example",
            parentEntityID: nil,
            sortOrder: nil,
            hasSourceMedia: false,
            capabilities: [
                .dates(
                    EntityItemsCapability(items: [
                        EntityDate(code: "released", value: "2026-07-24"),
                        EntityDate(code: "theatrical-release", value: "2026-07-25"),
                        EntityDate(code: "digital-release", value: "2026-08-14"),
                        EntityDate(code: "physical-release", value: "2026-09-22"),
                    ]))
            ],
            childrenByKind: [],
            relationships: []
        )

        XCTAssertEqual(
            EntityDetailPresentation(detail: detail).metadata.map(\.label),
            ["Theatrical release", "Digital / VOD release", "Physical release", "General release"]
        )
    }

    func testEntityDetailWantedChipUsesTheLoadedAcquisitionStatus() {
        let detail = EntityDetail(
            id: UUID(),
            kind: .movie,
            title: "Future Movie",
            parentEntityID: nil,
            sortOrder: nil,
            hasSourceMedia: false,
            capabilities: [
                .flags(
                    EntityFlagsCapability(
                        isFavorite: false,
                        isNsfw: false,
                        isOrganized: false,
                        isWanted: true
                    ))
            ],
            childrenByKind: [],
            relationships: []
        )

        let presentation = EntityDetailPresentation(
            detail: detail,
            acquisitionStatus: AcquisitionStatus(rawValue: "waiting-for-release")
        )

        XCTAssertEqual(presentation.flagItems.map(\.title), ["Waiting"])
        XCTAssertEqual(presentation.flagItems.map(\.systemImage), ["calendar.badge.clock"])
    }

    func testStreamingAndDigitalProfilesPresentOnlyTheirCompatibleFallback() {
        XCTAssertEqual(EntityDateType.streamingRelease.compatibleFallback, .digitalRelease)
        XCTAssertEqual(EntityDateType.digitalRelease.compatibleFallback, .streamingRelease)
        XCTAssertNil(EntityDateType.theatricalRelease.compatibleFallback)
        XCTAssertEqual(
            AdministrativeAcquisitionProfileTimingPolicy.compatibilityDescription(for: .streamingRelease),
            "Uses streaming release first, then digital / vod release when the exact milestone is unavailable."
        )
    }

    func testAcquisitionProfileMilestonesComeFromGeneratedEntityDefinitions() {
        XCTAssertEqual(
            AdministrativeAcquisitionProfileTimingPolicy.supportedTypes(for: .movie),
            EntityKind.movie.definition?.acquisitionProfile?.supportedReleaseDateTypes
        )
        XCTAssertEqual(
            AdministrativeAcquisitionProfileTimingPolicy.supportedTypes(for: .videoEpisode),
            EntityKind.videoSeries.definition?.acquisitionProfile?.supportedReleaseDateTypes
        )
        XCTAssertEqual(
            AdministrativeAcquisitionProfileTimingPolicy.supportedTypes(for: .bookVolume),
            EntityKind.book.definition?.acquisitionProfile?.supportedReleaseDateTypes
        )
    }

    func testProfileSaveContractCarriesReleaseTimingAndImmediateDefaultsToZeroDelay() throws {
        let profile = AdministrativeAcquisitionProfile(
            id: UUID(),
            kind: .movie,
            displayName: "Movie Default",
            isDefault: true,
            targetLibraryRootID: UUID()
        )
        let gated = AdministrativeAcquisitionProfileSaveRequest(
            profile: profile,
            searchAfterDateType: .streamingRelease,
            searchDelayDays: 2
        )
        let immediate = AdministrativeAcquisitionProfileSaveRequest(
            profile: profile,
            searchAfterDateType: nil,
            searchDelayDays: 15
        )

        let gatedJSON = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(gated)) as? [String: Any]
        )
        XCTAssertEqual(gatedJSON["searchAfterDateType"] as? String, "streaming-release")
        XCTAssertEqual(gatedJSON["searchDelayDays"] as? Int, 2)
        XCTAssertEqual(immediate.searchDelayDays, 0)
    }

    func testCalendarParentTitleAndNavigationTargetUseActualChildEntity() {
        let parentID = UUID()
        let childID = UUID()
        let event = calendarEvent(entityID: childID, parentEntityID: parentID, parentTitle: "Example Series")

        XCTAssertEqual(ReleaseCalendarPresentationPolicy.title(for: event), "Example Series · Episode One")
        let link = ReleaseCalendarPresentationPolicy.entityLink(for: event)
        XCTAssertEqual(link.entityID, childID)
        XCTAssertEqual(link.kind, .video)
        XCTAssertEqual(link.parentEntityID, parentID)
        XCTAssertEqual(link.parentKind, .videoSeries)
    }

    func testCrowdedDaysUseThreeVisibleEntriesAndOverflow() {
        XCTAssertEqual(ReleaseCalendarDatePolicy.visibleDayEventLimit, 3)
        let events = (0..<6).map { index in
            calendarEvent(title: "Episode \(index + 1)")
        }
        let grouped = ReleaseCalendarPresentationPolicy.groupedByDay(events)
        let day = ReleaseCalendarDatePolicy.date(from: "2026-08-14")!

        XCTAssertEqual(grouped[day]?.count, 6)
        XCTAssertEqual(grouped[day]?.prefix(ReleaseCalendarDatePolicy.visibleDayEventLimit).count, 3)
    }

    func testReleaseCalendarPreloadsStableAdjacentMonthKeys() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let january31 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 31))!

        let months = ReleaseCalendarDatePolicy.preloadMonths(
            around: january31,
            calendar: calendar
        )

        XCTAssertEqual(
            months.map { ReleaseCalendarDatePolicy.monthCacheKey(for: $0, calendar: calendar) },
            ["2025-12-01", "2026-01-01", "2026-02-01"]
        )
        XCTAssertEqual(
            ReleaseCalendarDatePolicy.monthCacheKey(for: january31, calendar: calendar),
            "2026-01-01"
        )
    }

    func testReleaseCalendarClientUsesCanonicalRouteQueryAndWireShape() async throws {
        let entityID = UUID()
        let monitorID = UUID()
        let loader = MockHTTPDataLoader(responses: [
            .json(
                """
                [{
                  "entityId":"\(entityID.uuidString)",
                  "monitorId":"\(monitorID.uuidString)",
                  "acquisitionId":null,
                  "kind":"movie",
                  "title":"Example",
                  "parentEntityId":null,
                  "parentKind":null,
                  "parentTitle":null,
                  "dateType":"streaming-release",
                  "value":"2026-08-14",
                  "date":"2026-08-14",
                  "precision":"day",
                  "acquisitionStatus":"waiting-for-release",
                  "isSearchGate":true,
                  "searchNotBefore":"2026-08-16",
                  "isSearchEligible":false,
                  "posterUrl":"/assets/example.jpg"
                }]
                """
            )
        ])
        let client = PrismediaAPIClient(
            serverURL: URL(string: "https://media.example.test")!,
            accessToken: "token",
            loader: loader
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 8, day: 31))!

        let events = try await client.releaseCalendar(from: start, through: end, calendar: calendar)

        XCTAssertEqual(loader.requests.first?.url?.path, "/api/calendar/releases")
        let query = URLComponents(url: loader.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems
        XCTAssertEqual(query?.first(where: { $0.name == "start" })?.value, "2026-08-01")
        XCTAssertEqual(query?.first(where: { $0.name == "end" })?.value, "2026-08-31")
        XCTAssertEqual(events.first?.dateType, .streamingRelease)
        XCTAssertEqual(events.first?.acquisitionStatus?.rawValue, "waiting-for-release")
        XCTAssertEqual(events.first?.searchNotBefore, "2026-08-16")
    }

    func testAcquisitionSummaryDefaultsPromptFlagAndDecodesTrue() throws {
        func decode(flag: String) throws -> RequestActivityAcquisitionSummary {
            try PrismediaJSON.decoder().decode(
                RequestActivityAcquisitionSummary.self,
                from: Data(
                    """
                    {
                      "id":"\(UUID().uuidString)",
                      "status":"waiting-for-release",
                      "title":"Example",
                      "createdAt":"2026-07-27T10:00:00Z",
                      "updatedAt":"2026-07-27T10:00:00Z",
                      "kind":"movie"\(flag)
                    }
                    """.utf8
                )
            )
        }

        XCTAssertFalse(try decode(flag: "").releaseDateMetadataUnavailable)
        XCTAssertTrue(
            try decode(flag: ",\"releaseDateMetadataUnavailable\":true")
                .releaseDateMetadataUnavailable
        )
    }

    private func calendarEvent(
        entityID: UUID = UUID(),
        parentEntityID: UUID? = nil,
        parentTitle: String? = nil,
        title: String = "Episode One"
    ) -> ReleaseCalendarEvent {
        ReleaseCalendarEvent(
            entityID: entityID,
            monitorID: UUID(),
            kind: .video,
            title: title,
            parentEntityID: parentEntityID,
            parentKind: parentEntityID == nil ? nil : .videoSeries,
            parentTitle: parentTitle,
            dateType: .air,
            value: "2026-08-14",
            date: "2026-08-14",
            precision: .day
        )
    }
}
