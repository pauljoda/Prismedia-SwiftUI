import XCTest

@testable import PrismediaCore

@MainActor
final class VideoPlaybackEnginePreferenceTests: XCTestCase {
    func testUserCanChoosePrismediaOrNativePlayback() {
        XCTAssertEqual(VideoPlaybackEngine.userSelectableCases, [.automatic, .native])
    }

    func testCompatibilityProfileAdvertisesMatroskaAndRichAudio() throws {
        let profile = AppleDeviceProfile.make(supportsCompatibilityRenderer: true)
        let matroska = try XCTUnwrap(
            profile.directPlayProfiles.first { $0.container.contains("mkv") }
        )

        XCTAssertTrue(matroska.videoCodec.contains("h264"))
        XCTAssertTrue(matroska.audioCodec.contains("truehd"))
        XCTAssertTrue(matroska.audioCodec.contains("mlp"))
        XCTAssertTrue(matroska.audioCodec.contains("dts"))
    }

    func testNativeProfileDoesNotAdvertiseMatroska() {
        let profile = AppleDeviceProfile.make(supportsCompatibilityRenderer: false)

        XCTAssertFalse(
            profile.directPlayProfiles.contains { $0.container.contains("mkv") }
        )
    }

    func testH264DirectPlaybackIsLimitedToHardwareDecodableBitDepth() throws {
        let profile = AppleDeviceProfile.make(supportsCompatibilityRenderer: true)
        let h264 = try XCTUnwrap(profile.codecProfiles.first { $0.codec == "h264" })
        let bitDepth = try XCTUnwrap(
            h264.conditions.first { $0.property == "VideoBitDepth" }
        )

        XCTAssertEqual(bitDepth.condition, "LessThanEqual")
        XCTAssertEqual(bitDepth.value, "8")
        XCTAssertTrue(bitDepth.isRequired)
    }

    func testPreferencesPersistSelectedEngine() {
        let suiteName = "VideoPlaybackEnginePreferenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsVideoPlaybackEnginePreferenceStore(defaults: defaults)
        let preferences = VideoPlaybackPreferences(store: store)

        XCTAssertEqual(preferences.engine, .automatic)

        preferences.engine = .native

        XCTAssertEqual(VideoPlaybackPreferences(store: store).engine, .native)
    }

    func testLegacyVLCPreferenceMigratesToPrismediaPlayback() {
        let suiteName = "VideoPlaybackEnginePreferenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("vlc", forKey: UserDefaultsVideoPlaybackEnginePreferenceStore.key)

        let preferences = VideoPlaybackPreferences(
            store: UserDefaultsVideoPlaybackEnginePreferenceStore(defaults: defaults)
        )

        XCTAssertEqual(preferences.engine, .automatic)
    }

    func testUnknownPersistedValueFallsBackToAutomatic() {
        let suiteName = "VideoPlaybackEnginePreferenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("future-engine", forKey: UserDefaultsVideoPlaybackEnginePreferenceStore.key)

        let preferences = VideoPlaybackPreferences(
            store: UserDefaultsVideoPlaybackEnginePreferenceStore(defaults: defaults)
        )

        XCTAssertEqual(preferences.engine, VideoPlaybackEngine.defaultChoice)
    }
}
