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

    func testDolbyVisionProfile5HonorsConfiguredNetworkCaching() {
        XCTAssertEqual(
            VLCNetworkCachingSettings.milliseconds(for: 3, dolbyVisionProfile: 5),
            3_000
        )
        XCTAssertEqual(
            VLCNetworkCachingSettings.milliseconds(for: 45, dolbyVisionProfile: 5),
            45_000
        )
        XCTAssertEqual(
            VLCNetworkCachingSettings.milliseconds(for: 3, dolbyVisionProfile: 8),
            3_000
        )
        XCTAssertEqual(
            VLCNetworkCachingSettings.milliseconds(for: 3, dolbyVisionProfile: nil),
            3_000
        )
    }

    func testProfile5UsesPatchedDecoderAndRendererOnEveryApplePlatform() {
        for platform in VLCCompatibilityPlaybackPlatform.allCases {
            let mediaOptions = VLCCompatibilityPlaybackOptions.mediaOptions(
                dolbyVisionProfile: 5,
                platform: platform,
                hardwareDecoderAvailable: true
            )
            let playerOptions = VLCCompatibilityPlaybackOptions.playerOptions(
                dolbyVisionProfile: 5,
                platform: platform
            )

            XCTAssertTrue(mediaOptions.contains(VLCCompatibilityPlaybackOptions.videoToolboxCodec))
            XCTAssertTrue(mediaOptions.contains(VLCCompatibilityPlaybackOptions.hardwareDecoderOnly))
            XCTAssertTrue(mediaOptions.contains(VLCCompatibilityPlaybackOptions.profile5Metadata))
            XCTAssertTrue(playerOptions.contains(VLCCompatibilityPlaybackOptions.quietLogging))
            XCTAssertTrue(playerOptions.contains(VLCCompatibilityPlaybackOptions.quietVerbosity))
            XCTAssertTrue(playerOptions.contains(VLCCompatibilityPlaybackOptions.profile5Reshape))
        }
    }

    func testProfile5UsesEachPlatformsNativeOpenGLSurfacePath() {
        for platform in [
            VLCCompatibilityPlaybackPlatform.iOS,
            VLCCompatibilityPlaybackPlatform.tvOS,
        ] {
            XCTAssertTrue(
                VLCCompatibilityPlaybackOptions.mediaOptions(
                    dolbyVisionProfile: 5,
                    platform: platform,
                    hardwareDecoderAvailable: true
                ).contains(VLCCompatibilityPlaybackOptions.profile5FullRangeSurface)
            )
            XCTAssertTrue(
                VLCCompatibilityPlaybackOptions.playerOptions(
                    dolbyVisionProfile: 5,
                    platform: platform
                ).contains(VLCCompatibilityPlaybackOptions.glesVideoOutput)
            )
        }

        XCTAssertFalse(
            VLCCompatibilityPlaybackOptions.mediaOptions(
                dolbyVisionProfile: 5,
                platform: .macOS,
                hardwareDecoderAvailable: true
            ).contains(VLCCompatibilityPlaybackOptions.profile5FullRangeSurface)
        )
        XCTAssertFalse(
            VLCCompatibilityPlaybackOptions.playerOptions(
                dolbyVisionProfile: 5,
                platform: .macOS
            ).contains(VLCCompatibilityPlaybackOptions.glesVideoOutput)
        )
    }

    func testProfile5OptionsRemainScopedToProfileFive() {
        XCTAssertEqual(
            VLCCompatibilityPlaybackOptions.mediaOptions(
                dolbyVisionProfile: 8,
                platform: .iOS,
                hardwareDecoderAvailable: true
            ),
            [
                VLCCompatibilityPlaybackOptions.videoToolboxCodec,
                VLCCompatibilityPlaybackOptions.hardwareDecoderOnly,
                VLCCompatibilityPlaybackOptions.avcodecVideoToolbox,
            ]
        )
        XCTAssertEqual(
            VLCCompatibilityPlaybackOptions.playerOptions(
                dolbyVisionProfile: 8,
                platform: .iOS
            ),
            [
                VLCCompatibilityPlaybackOptions.quietLogging,
                VLCCompatibilityPlaybackOptions.quietVerbosity,
            ]
        )
        XCTAssertTrue(
            VLCCompatibilityPlaybackOptions.mediaOptions(
                dolbyVisionProfile: 5,
                platform: .iOS,
                hardwareDecoderAvailable: false
            ).isEmpty
        )
    }

    func testCompatibilityPlaybackSuppressesVLCKitConsoleLoggingOnEveryPlatform() {
        for platform in VLCCompatibilityPlaybackPlatform.allCases {
            XCTAssertTrue(
                VLCCompatibilityPlaybackOptions.playerOptions(
                    dolbyVisionProfile: nil,
                    platform: platform
                ).contains(VLCCompatibilityPlaybackOptions.quietLogging)
            )
            XCTAssertTrue(
                VLCCompatibilityPlaybackOptions.playerOptions(
                    dolbyVisionProfile: nil,
                    platform: platform
                ).contains(VLCCompatibilityPlaybackOptions.quietVerbosity)
            )
        }
    }

    func testTrustedMatroskaDemuxIsScopedToValidatedDirectMatroskaRequests() {
        XCTAssertEqual(
            VLCCompatibilityPlaybackOptions.containerOptions(trustMatroskaCues: true),
            [VLCCompatibilityPlaybackOptions.trustedMatroskaDemux]
        )
        XCTAssertTrue(
            VLCCompatibilityPlaybackOptions.containerOptions(trustMatroskaCues: false).isEmpty
        )
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

        XCTAssertEqual(preferences.vlcNetworkCachingSeconds, VLCNetworkCachingSettings.defaultSeconds)

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
