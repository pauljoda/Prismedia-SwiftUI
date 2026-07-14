import Foundation
import XCTest

final class VideoObservationArchitectureTests: XCTestCase {
    func testVideoPlaybackPresentationUsesObservationWithoutLegacySwiftUIWrappers() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let relativePaths = [
            "PrismediaShared/Features/Playback/Video/Services/VideoPlaybackController.swift",
            "PrismediaShared/Features/Playback/Video/Services/VideoPlaybackPreparationCoordinator.swift",
            "PrismediaShared/Infrastructure/PlatformAdapters/Playback/VideoPictureInPictureCoordinator.swift",
            "PrismediaShared/Features/Playback/Video/Components/PrismediaVideoPlayerView.swift",
            "PrismediaShared/Features/Playback/Video/Components/VideoEntityPlaybackView.swift",
            "PrismediaShared/Features/Playback/Video/Components/VideoFilmstripView.swift",
        ]
        let forbiddenPatterns = [
            "ObservableObject",
            "@Published",
            "@ObservedObject",
            "@StateObject",
        ]

        let sources = try relativePaths.map { path in
            try String(
                contentsOf: repositoryRoot.appending(path: path),
                encoding: .utf8
            )
        }
        let violations = zip(relativePaths, sources).flatMap { path, source in
            forbiddenPatterns.compactMap { pattern in
                source.contains(pattern) ? "\(path): \(pattern)" : nil
            }
        }

        XCTAssertTrue(
            sources[0].contains("@Observable"),
            "VideoPlaybackController must publish presentation state through Observation."
        )
        XCTAssertTrue(
            sources[1].contains("@Observable"),
            "Deferred playback preparation must publish its phase through Observation."
        )
        XCTAssertTrue(
            sources[2].contains("@Observable"),
            "The PiP coordinator must publish presentation state through Observation."
        )
        XCTAssertEqual(violations, [])
    }

    func testFilmstripUsesPlatformNeutralImageIODecoding() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(
            contentsOf: repositoryRoot.appending(
                path: "PrismediaShared/Features/Playback/Video/Components/VideoFilmstripView.swift"
            ),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("import ImageIO"))
        XCTAssertFalse(source.contains("import UIKit"))
        XCTAssertFalse(source.contains("import AppKit"))
        XCTAssertFalse(source.contains("UIImage"))
        XCTAssertFalse(source.contains("NSImage"))
    }

    func testRemountedVideoSurfaceReadsReadyContentFromPageOwnedCoordinator() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(
            contentsOf: repositoryRoot.appending(
                path: "PrismediaShared/Features/Playback/Video/Components/VideoEntityPlaybackView.swift"
            ),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("videoDetail ?? preparation.videoDetail"))
        XCTAssertTrue(source.contains("playbackController ?? preparation.controller"))
        XCTAssertFalse(source.contains("synchronizePreparedPlayback"))
    }

    func testAudioAndVideoUsePlayerScopedNowPlayingSessions() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let audioSource = try String(
            contentsOf: repositoryRoot.appending(
                path: "PrismediaShared/Infrastructure/PlatformAdapters/Playback/MusicRemoteCommandCoordinator.swift"
            ),
            encoding: .utf8
        )
        let videoSource = try String(
            contentsOf: repositoryRoot.appending(
                path: "PrismediaShared/Infrastructure/PlatformAdapters/Playback/VideoNowPlayingCoordinator.swift"
            ),
            encoding: .utf8
        )

        XCTAssertTrue(audioSource.contains("MPNowPlayingSession(players:"))
        XCTAssertFalse(audioSource.contains("MPNowPlayingInfoCenter.default()"))
        XCTAssertFalse(audioSource.contains("MPRemoteCommandCenter.shared()"))
        XCTAssertTrue(videoSource.contains("MPNowPlayingSession(players:"))
        XCTAssertTrue(videoSource.contains("automaticallyPublishesNowPlayingInfo = true"))
        XCTAssertTrue(videoSource.contains("currentItem.externalMetadata ="))
        XCTAssertTrue(videoSource.contains("currentItem.nowPlayingInfo ="))
    }

    func testTVFullscreenPlaybackTransfersTheVisibleControllerWhenAdvancing() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let playbackViewSource = try String(
            contentsOf: repositoryRoot.appending(
                path: "PrismediaShared/Features/Playback/Video/Components/VideoEntityPlaybackView.swift"
            ),
            encoding: .utf8
        )

        XCTAssertTrue(
            playbackViewSource.contains("tvFullscreenPresentation?.updateController(controller)")
        )
        XCTAssertTrue(playbackViewSource.contains(".task(id: ObjectIdentifier(controller))"))
    }
}
