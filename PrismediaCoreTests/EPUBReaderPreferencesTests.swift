import XCTest

@testable import PrismediaCore

final class EPUBReaderPreferencesTests: XCTestCase {
    func testDefaultsMatchAConventionalReflowableReader() {
        let preferences = EPUBReaderPreferences()

        XCTAssertEqual(preferences.flow, .paged)
        XCTAssertEqual(preferences.theme, .system)
        XCTAssertEqual(preferences.fontFamily, .publisher)
        XCTAssertEqual(preferences.fontScale, 1)
        XCTAssertEqual(preferences.lineHeight, 1.5)
        XCTAssertEqual(preferences.pageMargins, 1)
    }

    func testValuesClampToReaderSafeRanges() {
        let preferences = EPUBReaderPreferences(
            flow: .scrolled,
            theme: .sepia,
            fontFamily: .serif,
            fontScale: 9,
            lineHeight: 0.2,
            pageMargins: -4
        )

        XCTAssertEqual(preferences.fontScale, 2)
        XCTAssertEqual(preferences.lineHeight, 1.2)
        XCTAssertEqual(preferences.pageMargins, 0.5)
    }

    func testPreferenceStoreRoundTripsAndFallsBackFromCorruptData() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: #function))
        suite.removePersistentDomain(forName: #function)
        defer { suite.removePersistentDomain(forName: #function) }
        let store = ReaderPreferencesStore(defaults: suite)
        let expected = EPUBReaderPreferences(
            flow: .scrolled,
            theme: .dark,
            fontFamily: .sansSerif,
            fontScale: 1.3,
            lineHeight: 1.7,
            pageMargins: 1.2
        )

        store.save(expected)
        XCTAssertEqual(store.loadEPUB(), expected)

        suite.set(Data("not-json".utf8), forKey: ReaderPreferencesStore.epubDefaultsKey)
        XCTAssertEqual(store.loadEPUB(), EPUBReaderPreferences())
    }
}
