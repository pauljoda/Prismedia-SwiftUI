import XCTest

@testable import PrismediaCore

final class VideoSubtitleAppearanceTests: XCTestCase {
    func testAppearanceClampsValuesToTheSharedPlaybackContract() {
        let appearance = VideoSubtitleAppearance(
            style: .outline,
            fontScale: 4,
            positionPercent: -12,
            opacity: 0.1
        )

        XCTAssertEqual(appearance.fontScale, 3)
        XCTAssertEqual(appearance.positionPercent, 0)
        XCTAssertEqual(appearance.opacity, 0.2)
    }

    func testSettingsDecodeWeightedSubtitlePreferenceTerms() throws {
        let data = Data(
            #"{"values":{"subtitles.autoEnable":true,"subtitles.preferredLanguages":[{"term":"Forced","weight":80},{"term":"English","weight":55},{"term":"Eng","weight":35}],"subtitles.style":"classic","subtitles.fontScale":1.4,"subtitles.positionPercent":92,"subtitles.opacity":0.75}}"#
                .utf8
        )

        let response = try PrismediaJSON.decoder().decode(VideoSubtitleSettingsResponse.self, from: data)
        let settings = VideoSubtitleSettings(values: response.values)

        XCTAssertTrue(settings.autoEnable)
        XCTAssertEqual(
            settings.preferredTerms,
            [
                SubtitlePreferenceTerm(term: "Forced", weight: 80),
                SubtitlePreferenceTerm(term: "English", weight: 55),
                SubtitlePreferenceTerm(term: "Eng", weight: 35),
            ]
        )
        XCTAssertEqual(settings.appearance.style, .classic)
        XCTAssertEqual(settings.appearance.fontScale, 1.4)
        XCTAssertEqual(settings.appearance.positionPercent, 92)
        XCTAssertEqual(settings.appearance.opacity, 0.75)
    }

    func testUnknownStyleAndMalformedValuesFallBackSafely() {
        let settings = VideoSubtitleSettings(values: [
            "subtitles.style": .string("neon"),
            "subtitles.fontScale": .string("large"),
        ])

        XCTAssertEqual(settings, .default)
    }

    func testPreferredTrackAddsEveryCaseInsensitiveMatchingTerm() {
        let english = EntitySubtitle(
            id: "english",
            language: "eng",
            label: "English",
            format: "vtt",
            source: "sidecar",
            storagePath: "/tmp/english.vtt",
            sourceFormat: "vtt",
            sourcePath: nil,
            isDefault: false
        )
        let englishForced = EntitySubtitle(
            id: "english-forced",
            language: "ENG",
            label: "English Forced",
            format: "vtt",
            source: "sidecar",
            storagePath: "/tmp/english-forced.vtt",
            sourceFormat: "vtt",
            sourcePath: nil,
            isDefault: false
        )
        let japaneseForced = EntitySubtitle(
            id: "japanese-forced",
            language: "jpn",
            label: "Japanese Forced",
            format: "vtt",
            source: "sidecar",
            storagePath: "/tmp/japanese-forced.vtt",
            sourceFormat: "vtt",
            sourcePath: nil,
            isDefault: false
        )

        XCTAssertEqual(
            VideoSubtitleLanguageMatcher.preferredTrack(
                in: [english, englishForced, japaneseForced],
                terms: [
                    SubtitlePreferenceTerm(term: "forced", weight: 80),
                    SubtitlePreferenceTerm(term: "English", weight: 55),
                    SubtitlePreferenceTerm(term: "Eng", weight: 35),
                ]
            )?.id,
            "english-forced"
        )
    }
}
