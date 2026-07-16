import XCTest

@testable import PrismediaCore

final class EPUBReaderPreferencesTests: XCTestCase {
    func testValuesClampToReaderSafeRanges() {
        let preferences = EPUBReaderPreferences(
            flow: .scrolled,
            theme: .sepia,
            fontFamily: .serif,
            fontScale: 9,
            fontWeight: 8,
            lineHeight: 0.2,
            letterSpacing: -2,
            wordSpacing: 9,
            paragraphSpacing: 8,
            paragraphIndent: -4,
            pageMargins: -4,
            textAlignment: .justified,
            columnCount: .two,
            hyphenationEnabled: true,
            textNormalizationEnabled: true,
            usesPublisherStyles: false,
            scrollFocusEnabled: true,
            scrollFocusStrength: 9,
            readingGuideEnabled: true
        )

        XCTAssertEqual(preferences.fontScale, 2)
        XCTAssertEqual(preferences.fontWeight, 1.5)
        XCTAssertEqual(preferences.lineHeight, 1.2)
        XCTAssertEqual(preferences.letterSpacing, 0)
        XCTAssertEqual(preferences.wordSpacing, 0.5)
        XCTAssertEqual(preferences.paragraphSpacing, 1.5)
        XCTAssertEqual(preferences.paragraphIndent, 0)
        XCTAssertEqual(preferences.pageMargins, 0.5)
        XCTAssertEqual(preferences.scrollFocusStrength, 0.8)
    }

    func testEveryBuiltInReadingProfileCanBeRecognizedAfterApplyingIt() {
        for profile in EPUBReadingProfile.selectableCases {
            XCTAssertEqual(profile.preferences.matchingProfile, profile)
        }
    }

    func testLegacyPreferencesKeepPublisherFormattingWhenNewFieldsAreAbsent() throws {
        let data = Data(
            """
            {
              "flow": "paged",
              "theme": "system",
              "fontFamily": "publisher",
              "fontScale": 1.1,
              "lineHeight": 1.5,
              "pageMargins": 1.0
            }
            """.utf8
        )

        let preferences = try JSONDecoder().decode(EPUBReaderPreferences.self, from: data)

        XCTAssertTrue(preferences.usesPublisherStyles)
        XCTAssertEqual(preferences.textAlignment, .automatic)
        XCTAssertEqual(preferences.columnCount, .automatic)
        XCTAssertFalse(preferences.scrollFocusEnabled)
        XCTAssertFalse(preferences.readingGuideEnabled)
    }

    func testPreferenceStoreRoundTripsAndFallsBackFromCorruptData() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: #function))
        suite.removePersistentDomain(forName: #function)
        defer { suite.removePersistentDomain(forName: #function) }
        let store = ReaderPreferencesStore(defaults: suite)
        let expected = EPUBReaderPreferences(
            flow: .scrolled,
            theme: .dark,
            fontFamily: .accessible,
            fontScale: 1.3,
            fontWeight: 1.15,
            lineHeight: 1.7,
            letterSpacing: 0.1,
            wordSpacing: 0.2,
            paragraphSpacing: 0.4,
            paragraphIndent: 0,
            pageMargins: 1.2,
            textAlignment: .leading,
            columnCount: .one,
            hyphenationEnabled: false,
            textNormalizationEnabled: true,
            usesPublisherStyles: false,
            scrollFocusEnabled: true,
            scrollFocusStrength: 0.55,
            readingGuideEnabled: true
        )

        store.save(expected)
        XCTAssertEqual(store.loadEPUB(), expected)

        suite.set(Data("not-json".utf8), forKey: ReaderPreferencesStore.epubDefaultsKey)
        XCTAssertEqual(store.loadEPUB(), EPUBReaderPreferences())
    }
}
