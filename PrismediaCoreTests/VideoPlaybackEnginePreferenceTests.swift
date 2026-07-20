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
