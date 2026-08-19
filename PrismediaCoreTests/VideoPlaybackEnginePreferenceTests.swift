import XCTest

@testable import PrismediaCore

@MainActor
final class VideoPlaybackEnginePreferenceTests: XCTestCase {
    func testUserCanChoosePrismediaOrNativePlayback() {
        XCTAssertEqual(VideoPlaybackEngine.userSelectableCases, [.automatic, .native])
    }

    func testCompatibilityProfileAdvertisesMatroskaAndRichAudio() throws {
        let profile = AppleVideoPlaybackProfile.make(supportsCompatibilityRenderer: true)
        let matroska = try XCTUnwrap(
            profile.directPlayProfiles.first { $0.container.contains("mkv") }
        )

        XCTAssertTrue(matroska.videoCodec.contains("h264"))
        XCTAssertTrue(matroska.audioCodec.contains("truehd"))
        XCTAssertTrue(matroska.audioCodec.contains("mlp"))
        XCTAssertTrue(matroska.audioCodec.contains("dts"))
    }

    func testNativeProfileDoesNotAdvertiseMatroska() {
        let profile = AppleVideoPlaybackProfile.make(supportsCompatibilityRenderer: false)

        XCTAssertFalse(
            profile.directPlayProfiles.contains { $0.container.contains("mkv") }
        )
    }

    func testProfileUsesNativeStreamKindCode() {
        let profile = AppleVideoPlaybackProfile.make(supportsCompatibilityRenderer: true)

        XCTAssertTrue(
            profile.directPlayProfiles.allSatisfy {
                $0.type == PrismediaContractCodes.StreamKind.video
            }
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

    func testVLCNetworkCachingDefaultsToThreeSecondsAndConvertsToMilliseconds() {
        XCTAssertEqual(VLCNetworkCachingSettings.defaultSeconds, 3)
        XCTAssertEqual(VLCNetworkCachingSettings.milliseconds(for: 3), 3_000)
    }

    func testPreferencesPersistVLCNetworkCachingSeconds() {
        let suiteName = "VideoPlaybackEnginePreferenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engineStore = UserDefaultsVideoPlaybackEnginePreferenceStore(defaults: defaults)
        let cachingStore = UserDefaultsVLCNetworkCachingPreferenceStore(defaults: defaults)
        let preferences = VideoPlaybackPreferences(
            store: engineStore,
            vlcNetworkCachingStore: cachingStore
        )

        XCTAssertEqual(preferences.vlcNetworkCachingSeconds, 3)

        preferences.vlcNetworkCachingSeconds = 7

        XCTAssertEqual(
            VideoPlaybackPreferences(
                store: engineStore,
                vlcNetworkCachingStore: cachingStore
            ).vlcNetworkCachingSeconds,
            7
        )
    }

    func testInvalidPersistedVLCNetworkCachingValueFallsBackToDefault() {
        let suiteName = "VideoPlaybackEnginePreferenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(61, forKey: UserDefaultsVLCNetworkCachingPreferenceStore.key)

        let store = UserDefaultsVLCNetworkCachingPreferenceStore(defaults: defaults)

        XCTAssertEqual(store.loadSeconds(), VLCNetworkCachingSettings.defaultSeconds)
    }
}
