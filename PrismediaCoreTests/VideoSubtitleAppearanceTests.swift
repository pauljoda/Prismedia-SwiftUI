import XCTest

@testable import PrismediaCore

final class VideoSubtitleAppearanceTests: XCTestCase {
    func testDefaultsMatchTheWebPlayer() {
        XCTAssertEqual(VideoSubtitleAppearance.default.style, .stylized)
        XCTAssertEqual(VideoSubtitleAppearance.default.fontScale, 1)
        XCTAssertEqual(VideoSubtitleAppearance.default.positionPercent, 88)
        XCTAssertEqual(VideoSubtitleAppearance.default.opacity, 1)
        XCTAssertEqual(VideoSubtitleAppearance.default.bottomInsetFraction, 0.12, accuracy: 0.0001)
    }

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

    func testSettingsDecodeTheSixWebSubtitleKeys() throws {
        let data = Data(
            #"{"values":{"subtitles.autoEnable":true,"subtitles.preferredLanguages":["ja","jpn"],"subtitles.style":"classic","subtitles.fontScale":1.4,"subtitles.positionPercent":92,"subtitles.opacity":0.75}}"#
                .utf8
        )

        let response = try PrismediaJSON.decoder().decode(VideoSubtitleSettingsResponse.self, from: data)
        let settings = VideoSubtitleSettings(values: response.values)

        XCTAssertTrue(settings.autoEnable)
        XCTAssertEqual(settings.preferredLanguages, ["ja", "jpn"])
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

    func testPreferredTrackMatchesLanguageCodesLabelsAndISOAliases() {
        let english = EntitySubtitle(
            id: "english",
            language: "English",
            label: "English (SDH)",
            format: "vtt",
            source: "sidecar",
            storagePath: "/tmp/english.vtt",
            sourceFormat: "vtt",
            sourcePath: nil,
            isDefault: false
        )
        let japanese = EntitySubtitle(
            id: "japanese",
            language: "jpn",
            label: "Japanese",
            format: "vtt",
            source: "sidecar",
            storagePath: "/tmp/japanese.vtt",
            sourceFormat: "vtt",
            sourcePath: nil,
            isDefault: false
        )

        XCTAssertEqual(
            VideoSubtitleLanguageMatcher.preferredTrack(in: [english, japanese], languages: ["ja"])?.id,
            "japanese"
        )
        XCTAssertEqual(
            VideoSubtitleLanguageMatcher.preferredTrack(in: [english, japanese], languages: ["eng"])?.id,
            "english"
        )
    }
}
