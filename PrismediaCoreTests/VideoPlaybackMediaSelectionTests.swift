import AVFoundation
import XCTest

@testable import PrismediaCore

@MainActor
final class VideoPlaybackMediaSelectionTests: XCTestCase {
    private let videoID = UUID(uuidString: "91919191-9191-9191-9191-919191919191")!

    func testInstalledPlanUsesTheServerSelectedAudioStream() async {
        let service = MediaSelectionVideoService(videoID: videoID)
        let controller = VideoPlaybackController(
            videoID: videoID,
            service: service,
            audioSession: MediaSelectionAudioSession()
        )

        await controller.load()

        XCTAssertEqual(controller.selectedAudioChoiceID, "server-audio-2")
    }

    func testExplicitServerAudioSelectionRequestsTheIndexAndInstallsItsReplacementStream() async {
        let service = MediaSelectionVideoService(videoID: videoID)
        let controller = VideoPlaybackController(
            videoID: videoID,
            service: service,
            audioSession: MediaSelectionAudioSession()
        )
        await controller.load()

        await controller.selectAudio(id: "server-audio-3")

        let requestedAudioIndices = await service.requestedAudioIndices
        XCTAssertEqual(requestedAudioIndices, [nil, 3])
        XCTAssertEqual(controller.selectedAudioChoiceID, "server-audio-3")
        XCTAssertEqual(
            (controller.player.currentItem?.asset as? AVURLAsset)?.url.lastPathComponent,
            "audio-3.m3u8"
        )
    }

    func testAutoEnableSelectsThePreferredNormalizedSubtitle() async {
        let subtitle = subtitleTrack(id: "english", language: "eng", sourceFormat: "srt")
        let service = MediaSelectionVideoService(
            videoID: videoID,
            settings: .init(
                autoEnable: true,
                preferredLanguages: ["en"],
                appearance: .default
            ),
            mediaContents: "WEBVTT\n\n00:00:00.000 --> 00:00:05.000\nWelcome to <i>Jujutsu</i> High."
        )
        let controller = VideoPlaybackController(
            videoID: videoID,
            service: service,
            audioSession: MediaSelectionAudioSession(),
            sidecarSubtitles: [subtitle]
        )

        await controller.load()

        let requestedMediaPaths = await service.requestedMediaPaths
        XCTAssertEqual(controller.selectedSubtitleChoiceID, "sidecar-english")
        XCTAssertEqual(controller.activeSubtitleText, "Welcome to Jujutsu High.")
        XCTAssertEqual(
            controller.activeSubtitleContent?.runs,
            [
                VideoSubtitleTextRun(text: "Welcome to ", style: []),
                VideoSubtitleTextRun(text: "Jujutsu", style: [.italic]),
                VideoSubtitleTextRun(text: " High.", style: []),
            ]
        )
        XCTAssertEqual(
            requestedMediaPaths,
            ["/api/videos/91919191-9191-9191-9191-919191919191/subtitles/english"]
        )
    }

    func testSelectingAssFetchesThePreservedSourceForStyledRendering() async {
        let subtitle = subtitleTrack(id: "english", language: "eng", sourceFormat: "ass")
        let contents = """
            [Script Info]
            ScriptType: v4.00+

            [Events]
            Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
            Dialogue: 0,0:00:00.00,0:00:05.00,Default,,0,0,0,,Styled caption
            """
        let service = MediaSelectionVideoService(
            videoID: videoID,
            mediaContents: contents
        )
        let controller = VideoPlaybackController(
            videoID: videoID,
            service: service,
            audioSession: MediaSelectionAudioSession(),
            sidecarSubtitles: [subtitle]
        )
        await controller.load()

        await controller.selectSubtitle(id: "sidecar-english")

        let requestedMediaPaths = await service.requestedMediaPaths
        XCTAssertEqual(controller.selectedSubtitleChoiceID, "sidecar-english")
        XCTAssertEqual(controller.activeAssSubtitleContents, contents)
        XCTAssertNil(controller.activeSubtitleText)
        XCTAssertEqual(
            requestedMediaPaths,
            ["/api/videos/91919191-9191-9191-9191-919191919191/subtitles/english/source"]
        )
    }

    func testASSSelectionFallsBackToNormalizedWebVTTWhenPreservedSourceIsUnavailable() async {
        let subtitle = subtitleTrack(id: "english", language: "eng", sourceFormat: "ass")
        let contents = "WEBVTT\n\n00:00:00.000 --> 00:00:05.000\nFallback caption"
        let service = MediaSelectionVideoService(
            videoID: videoID,
            mediaContents: contents,
            failingMediaPathSuffix: "/source"
        )
        let controller = VideoPlaybackController(
            videoID: videoID,
            service: service,
            audioSession: MediaSelectionAudioSession(),
            sidecarSubtitles: [subtitle]
        )
        await controller.load()

        await controller.selectSubtitle(id: "sidecar-english")

        let requestedMediaPaths = await service.requestedMediaPaths
        XCTAssertNil(controller.activeAssSubtitleContents)
        XCTAssertEqual(controller.activeSubtitleText, "Fallback caption")
        XCTAssertEqual(
            requestedMediaPaths,
            [
                "/api/videos/91919191-9191-9191-9191-919191919191/subtitles/english/source",
                "/api/videos/91919191-9191-9191-9191-919191919191/subtitles/english",
            ]
        )
    }

    func testPlatformsWithoutASSRenderingUseNormalizedWebVTTForEveryManagedFormat() {
        for sourceFormat in ["ass", "ssa", "srt", "vtt"] {
            XCTAssertFalse(
                VideoSidecarSubtitlePolicy.usesPreservedSource(
                    sourceFormat: sourceFormat,
                    sourcePath: "subtitles/english.\(sourceFormat)",
                    supportsAssRenderer: false
                )
            )
        }
    }

    func testASSCapablePlatformsPreserveOnlyASSAndSSA() {
        XCTAssertTrue(
            VideoSidecarSubtitlePolicy.usesPreservedSource(
                sourceFormat: "ass",
                sourcePath: "subtitles/english.ass",
                supportsAssRenderer: true
            )
        )
        XCTAssertTrue(
            VideoSidecarSubtitlePolicy.usesPreservedSource(
                sourceFormat: "SSA",
                sourcePath: "subtitles/english.ssa",
                supportsAssRenderer: true
            )
        )
        XCTAssertFalse(
            VideoSidecarSubtitlePolicy.usesPreservedSource(
                sourceFormat: "srt",
                sourcePath: "subtitles/english.srt",
                supportsAssRenderer: true
            )
        )
        XCTAssertFalse(
            VideoSidecarSubtitlePolicy.usesPreservedSource(
                sourceFormat: "vtt",
                sourcePath: "subtitles/english.vtt",
                supportsAssRenderer: true
            )
        )
        XCTAssertFalse(
            VideoSidecarSubtitlePolicy.usesPreservedSource(
                sourceFormat: "ass",
                sourcePath: nil,
                supportsAssRenderer: true
            )
        )
    }

    func testPreferredNativeSubtitleCandidateUsesLanguageTagBeforeDisplayName() {
        let candidates = [
            VideoSubtitleSelectionCandidate(
                id: "subtitle-0",
                language: "ja-JP",
                label: "Japanese"
            ),
            VideoSubtitleSelectionCandidate(
                id: "subtitle-1",
                language: "en-US",
                label: "English (SDH)"
            ),
        ]

        XCTAssertEqual(
            VideoSubtitleLanguageMatcher.preferredIdentifier(
                in: candidates,
                languages: ["eng"]
            ),
            "subtitle-1"
        )
    }

    private func subtitleTrack(
        id: String,
        language: String,
        sourceFormat: String
    ) -> EntitySubtitle {
        EntitySubtitle(
            id: id,
            language: language,
            label: "English",
            format: "vtt",
            source: "embedded",
            storagePath: "subtitles/\(id).vtt",
            sourceFormat: sourceFormat,
            sourcePath: sourceFormat == "ass" ? "subtitles/\(id).ass" : nil,
            isDefault: false
        )
    }
}

private struct MediaSelectionAudioSession: VideoAudioSessionPreparing {
    func prepare() async throws {}
}

private actor MediaSelectionVideoService: VideoPlaybackServicing {
    private(set) var requestedAudioIndices: [Int?] = []
    private(set) var requestedMediaPaths: [String] = []
    private let videoID: UUID
    private let settings: VideoSubtitleSettings
    private let mediaContents: String
    private let failingMediaPathSuffix: String?

    init(
        videoID: UUID,
        settings: VideoSubtitleSettings = .default,
        mediaContents: String = "",
        failingMediaPathSuffix: String? = nil
    ) {
        self.videoID = videoID
        self.settings = settings
        self.mediaContents = mediaContents
        self.failingMediaPathSuffix = failingMediaPathSuffix
    }

    func negotiateVideoPlayback(
        videoID: UUID,
        forceTranscode: Bool
    ) async throws -> VideoPlaybackPlan {
        try await negotiateVideoPlayback(
            videoID: videoID,
            forceTranscode: forceTranscode,
            audioStreamIndex: nil
        )
    }

    func negotiateVideoPlayback(
        videoID: UUID,
        forceTranscode: Bool,
        audioStreamIndex: Int?
    ) async throws -> VideoPlaybackPlan {
        requestedAudioIndices.append(audioStreamIndex)
        let fileName = audioStreamIndex.map { "audio-\($0).m3u8" } ?? "initial.mp4"
        return VideoPlaybackPlan(
            videoID: self.videoID,
            url: URL(string: "https://media.example.test/\(fileName)")!,
            delivery: audioStreamIndex == nil ? .direct : .remux,
            playSessionID: "selection-session",
            mediaSourceID: "selection-source",
            durationSeconds: 120,
            audioStreams: [
                .init(index: 2, title: "English AAC", isSelected: true),
                .init(index: 3, title: "Japanese AAC", isSelected: false),
            ]
        )
    }

    func mediaData(for path: String) async throws -> Data {
        requestedMediaPaths.append(path)
        if let failingMediaPathSuffix, path.hasSuffix(failingMediaPathSuffix) {
            throw URLError(.fileDoesNotExist)
        }
        return Data(mediaContents.utf8)
    }

    nonisolated func authenticatedMediaURL(for path: String) -> URL? {
        URL(string: "https://media.example.test\(path)")
    }

    func videoSubtitleSettings() async throws -> VideoSubtitleSettings { settings }
}
