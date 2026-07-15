import XCTest

@testable import PrismediaCore

final class EntityGridControlsTests: XCTestCase {
    func testPersistedPreferencesRestoreControlsWithoutReplacingRouteDefaults() throws {
        let baseline = EntityListQuery(
            kind: .book,
            sort: "added",
            bookType: "comic,manga"
        )
        var controls = EntityGridControls(baselineQuery: baseline)
        controls.sort = .rating
        controls.sortDescending = false
        controls.filters.favoriteOnly = true
        controls.filters.availability = .wanted
        controls.filters.acquisitionStatus = AcquisitionStatus(rawValue: "searching")
        controls.filters.rating = .atLeast(3)
        controls.filters.maximumRating = 5
        controls.filters.bookFormats = ["cbz", "pdf"]

        let preferences = EntityGridPreferences(
            controls: controls,
            displayMode: .list,
            density: .large,
            pageSize: 96
        )
        let restored = preferences.controls(baselineQuery: baseline)
        let query = restored.applying(to: baseline)

        XCTAssertEqual(restored.sort, .rating)
        XCTAssertFalse(restored.sortDescending)
        XCTAssertTrue(restored.filters.favoriteOnly)
        XCTAssertEqual(restored.filters.availability, .wanted)
        XCTAssertEqual(restored.filters.acquisitionStatus?.rawValue, "searching")
        XCTAssertEqual(restored.filters.rating, .atLeast(3))
        XCTAssertEqual(restored.filters.maximumRating, 5)
        XCTAssertEqual(restored.filters.bookFormats, ["cbz", "pdf"])
        XCTAssertEqual(preferences.displayMode, .list)
        XCTAssertEqual(preferences.density, .large)
        XCTAssertEqual(preferences.pageSize, 96)
        XCTAssertEqual(query.kind, .book)
        XCTAssertEqual(query.bookType, "comic,manga")
    }

    func testLegacyPreferencePayloadDefaultsToGridWithStandardDensity() throws {
        let legacyPayload = Data(
            #"{"sort":"title","sortDescending":false,"favoriteOnly":false,"organization":"any","availability":"any","engagement":"any","isUnrated":false,"taxonomy":"any","bookTypes":[],"bookFormats":[]}"#
                .utf8
        )

        let preferences = try JSONDecoder().decode(EntityGridPreferences.self, from: legacyPayload)

        XCTAssertEqual(preferences.displayMode, .grid)
        XCTAssertEqual(preferences.density, .standard)
        XCTAssertNil(preferences.pageSize)
        XCTAssertEqual(preferences.sort, "title")
    }

    func testConfigurationRejectsARestoredDisplayModeOutsideItsSupportedLayouts() {
        let configuration = EntityGridConfiguration(
            title: "Episodes",
            query: EntityListQuery(kind: .video),
            defaultDisplayMode: .list,
            availableDisplayModes: [.list]
        )

        XCTAssertEqual(configuration.resolvedDisplayMode(restoring: .grid), .list)
        XCTAssertEqual(configuration.resolvedDisplayMode(restoring: .list), .list)
        XCTAssertEqual(configuration.resolvedDisplayMode(restoring: nil), .list)
    }

    func testPreferencesEncodeUserControlsAsOneNestedValue() throws {
        var controls = EntityGridControls(baselineQuery: EntityListQuery(kind: .book))
        controls.sort = .rating
        controls.sortDescending = false
        controls.filters.favoriteOnly = true
        controls.filters.rating = .atLeast(4)

        let preferences = EntityGridPreferences(controls: controls)
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(preferences)) as? [String: Any]
        )
        let savedControls = try XCTUnwrap(object["controls"] as? [String: Any])

        XCTAssertEqual(savedControls["sort"] as? String, "rating")
        XCTAssertEqual(savedControls["sortDescending"] as? Bool, false)
        XCTAssertNil(object["favoriteOnly"], "Filter fields should not be mirrored at the preference root.")
    }

    func testPreferenceStoreKeepsGridSurfacesIndependentAndCanResetOne() throws {
        let suiteName = "EntityGridControlsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = EntityGridPreferencesStore(defaults: defaults)
        let videos = EntityGridPreferences(
            controls: controls(sort: .rating, favoriteOnly: true),
            displayMode: .list,
            density: .compact
        )
        let books = EntityGridPreferences(
            controls: controls(sort: .title, favoriteOnly: false),
            displayMode: .grid,
            density: .large
        )

        store.save(videos, for: "videos")
        store.save(books, for: "books")

        XCTAssertEqual(store.load(for: "videos"), videos)
        XCTAssertEqual(store.load(for: "books"), books)

        store.reset(for: "videos")

        XCTAssertNil(store.load(for: "videos"))
        XCTAssertEqual(store.load(for: "books"), books)
    }

    func testPreferenceStorePersistsNamedPresetsAndReplacesMatchingName() throws {
        let suiteName = "EntityGridPresetTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = EntityGridPreferencesStore(defaults: defaults)
        let compact = EntityGridPreferences(
            controls: controls(sort: .title, favoriteOnly: false),
            displayMode: .grid,
            density: .compact,
            pageSize: 24
        )
        let favorites = EntityGridPreferences(
            controls: controls(sort: .rating, favoriteOnly: true),
            displayMode: .list,
            density: .large,
            pageSize: 96
        )

        store.savePreset(named: "Favorites", preferences: compact, for: "videos")
        store.savePreset(named: "favorites", preferences: favorites, for: "videos")

        let presets = store.loadPresets(for: "videos")
        XCTAssertEqual(presets.count, 1)
        XCTAssertEqual(presets.first?.name, "Favorites")
        XCTAssertEqual(presets.first?.preferences, favorites)

        if let preset = presets.first {
            store.deletePreset(id: preset.id, for: "videos")
        }
        XCTAssertTrue(store.loadPresets(for: "videos").isEmpty)
    }

    func testControlsApplyServerSortAndFiltersWithoutRemovingRouteLocks() {
        let baseline = EntityListQuery(
            kind: .book,
            sort: "added",
            bookType: "comic,manga",
            bookFormat: "image-archive"
        )
        var controls = EntityGridControls(baselineQuery: baseline)
        controls.sort = .rating
        controls.sortDescending = false
        controls.filters.favoriteOnly = true
        controls.filters.organization = .unorganized
        controls.filters.availability = .wanted
        controls.filters.engagement = .inProgress
        controls.filters.rating = .atLeast(3)
        controls.filters.maximumRating = 4

        let query = controls.applying(to: baseline)

        XCTAssertEqual(query.kind, .book)
        XCTAssertEqual(query.sort, "rating")
        XCTAssertFalse(query.sortDescending)
        XCTAssertEqual(query.bookType, "comic,manga")
        XCTAssertEqual(query.bookFormat, "image-archive")
        XCTAssertEqual(query.favorite, true)
        XCTAssertEqual(query.organized, false)
        XCTAssertEqual(query.wanted, true)
        XCTAssertNil(query.hasFile)
        XCTAssertEqual(query.status, "in-progress")
        XCTAssertEqual(query.ratingMin, 3)
        XCTAssertEqual(query.ratingMax, 4)
        XCTAssertEqual(query.hideNsfw, true)
        XCTAssertNil(query.nsfw, "The API client owns the global NSFW safety policy.")
    }

    func testWantedVisibilityCanExcludeWantedEntitiesWithoutChangingAvailabilityFilter() {
        var controls = EntityGridControls(baselineQuery: EntityListQuery(kind: .movie))
        controls.filters.includeWanted = false

        let query = controls.applying(to: EntityListQuery(kind: .movie))

        XCTAssertEqual(query.wanted, false)
        XCTAssertNil(query.hasFile)
    }

    func testExplicitWantedAvailabilityOverridesHiddenWantedPreference() {
        var controls = EntityGridControls(baselineQuery: EntityListQuery(kind: .movie))
        controls.filters.includeWanted = false
        controls.filters.availability = .wanted

        let query = controls.applying(to: EntityListQuery(kind: .movie))

        XCTAssertEqual(query.wanted, true)
    }

    func testHiddenWantedPreferenceDoesNotOverrideWantedOnlyRoute() {
        let baseline = EntityListQuery(kind: .movie, wanted: true)
        var controls = EntityGridControls(baselineQuery: baseline)
        controls.filters.includeWanted = false

        let query = controls.applying(to: baseline)

        XCTAssertEqual(query.wanted, true)
    }

    func testRandomSortKeepsItsSeedInTheAppliedQuery() {
        var controls = EntityGridControls(baselineQuery: EntityListQuery(kind: .video))
        controls.sort = .random
        controls.randomSeed = 867_5309

        let query = controls.applying(to: EntityListQuery(kind: .video))

        XCTAssertEqual(query.sort, "random")
        XCTAssertEqual(query.seed, 867_5309)
    }

    func testGeneratedRandomSeedsAlwaysFitTheBackendInt32Contract() {
        for _ in 0..<100 {
            XCTAssertTrue((1...2_000_000_000).contains(EntityGridControls.nextRandomSeed()))
        }
    }

    func testEmptyControlsPreserveEveryServerConstraintOwnedByTheRoute() {
        let baseline = EntityListQuery(
            kind: .video,
            favorite: true,
            organized: true,
            ratingMin: 4,
            status: "watched",
            hasFile: true
        )

        let query = EntityGridControls(baselineQuery: baseline).applying(to: baseline)

        XCTAssertEqual(query.favorite, true)
        XCTAssertEqual(query.organized, true)
        XCTAssertEqual(query.ratingMin, 4)
        XCTAssertEqual(query.status, "watched")
        XCTAssertEqual(query.hasFile, true)
    }

    private func controls(
        sort: EntityGridSort,
        favoriteOnly: Bool
    ) -> EntityGridControls {
        var controls = EntityGridControls(baselineQuery: EntityListQuery(kind: .video))
        controls.sort = sort
        controls.filters.favoriteOnly = favoriteOnly
        return controls
    }
}
