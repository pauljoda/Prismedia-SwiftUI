import XCTest

@testable import PrismediaCore

final class AdministrativeLanguageCatalogTests: XCTestCase {
    private let locale = Locale(identifier: "en_US")

    func testOnlyLanguageCodeSettingsUseLanguageChoices() {
        XCTAssertTrue(AdministrativeLanguageCatalog.supports(key: PrismediaContractCodes.SettingKey.playbackAudioPreferredLanguages))
        XCTAssertTrue(AdministrativeLanguageCatalog.supports(key: PrismediaContractCodes.SettingKey.subtitlesAutoDownloadLanguages))
        XCTAssertFalse(AdministrativeLanguageCatalog.supports(key: PrismediaContractCodes.SettingKey.subtitlesPreferredLanguages))
    }

    func testLabelsPreserveDistinctSavedCodesAndRegionalMeaning() {
        let codes = ["en", "eng", "en-US", "custom-language"]
        let options = codes.map { AdministrativeLanguageCatalog.option(for: $0, locale: locale) }
        XCTAssertEqual(options.map(\.value), codes)
        XCTAssertEqual(options[0].label, "English")
        XCTAssertEqual(options[1].label, "English")
        XCTAssertTrue(options[2].label.contains("United States"))
        XCTAssertFalse(options[3].label.isEmpty)
    }

    func testSearchMatchesNamesAndCodesWithoutChangingSelection() {
        let options = AdministrativeLanguageCatalog.options(locale: locale)
        XCTAssertEqual(Set(options.map(\.value)).count, options.count)
        XCTAssertTrue(AdministrativeLanguageCatalog.matching("French", in: options).contains { $0.value == "fr" })
        XCTAssertTrue(AdministrativeLanguageCatalog.matching("fr", in: options).contains { $0.value == "fr" })
        XCTAssertEqual(AdministrativeLanguageCatalog.matching("  ", in: options), options)
    }
}
