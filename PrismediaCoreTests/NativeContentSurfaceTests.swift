import Foundation
import SwiftUI
import XCTest

@testable import PrismediaCore

final class NativeContentSurfaceTests: XCTestCase {
    @MainActor
    func testAppBackdropStaysBlackDominantWhileRetainingMutedSpectrumColor() throws {
        let backdrop = PrismediaBackdrop()
            .frame(width: 240, height: 240)
            .environment(\.colorScheme, .dark)

        let renderer = ImageRenderer(content: backdrop)
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.cgImage)
        let samples = try [
            rgbaPixel(from: image, x: image.width / 6, y: image.height / 5),
            rgbaPixel(from: image, x: image.width / 2, y: image.height / 2),
            rgbaPixel(from: image, x: image.width * 5 / 6, y: image.height * 4 / 5),
        ]
        let luminances = samples.map(luminance)
        let chromas = samples.map(normalizedChroma)

        XCTAssertTrue(samples.allSatisfy { $0.alpha == 255 }, "The app backdrop must remain fully opaque.")
        XCTAssertLessThan(luminances.max() ?? 1, 0.2, "Black must remain the dominant backdrop tone.")
        XCTAssertGreaterThan(chromas.max() ?? 0, 0.025, "The backdrop must retain a muted spectral haze.")
    }

    func testAppBackdropUsesTokenizedStaticSpectrumInsteadOfAdaptiveBrass() throws {
        let source = try sourceFile(
            "PrismediaShared/DesignSystem/Components/PrismediaBackdrop.swift"
        )

        XCTAssertTrue(source.contains("MeshGradient("))
        XCTAssertTrue(source.contains("PrismediaColor.spectrum"))
        XCTAssertTrue(source.contains("PrismediaOpacity.backdropSpectrum"))
        XCTAssertTrue(source.contains(".allowsHitTesting(false)"))
        XCTAssertTrue(source.contains(".accessibilityHidden(true)"))
        XCTAssertFalse(source.contains("brandGold"))
        XCTAssertFalse(source.contains("colorScheme"))
        XCTAssertFalse(source.contains("animation"))
    }

    func testThemeUsesACoolInteractiveAccentAndRetiresBrassRoles() throws {
        let colors = try sourceFile(
            "PrismediaShared/DesignSystem/Tokens/PrismediaColor.swift"
        )
        let subtitles = try sourceFile(
            "PrismediaShared/Features/Playback/Video/Components/VideoSubtitleOverlay.swift"
        )
        let accent = try sourceFile(
            "PrismediaShared/Resources/Brand.xcassets/PrismediaAccent.colorset/Contents.json"
        )
        let retiredAsset =
            repositoryRoot
            .appending(path: "PrismediaShared/Resources/Brand.xcassets/PrismediaBrandGold.colorset")

        XCTAssertFalse(colors.contains("brandGold"))
        XCTAssertFalse(subtitles.contains("brandGold"))
        XCTAssertTrue(subtitles.contains("PrismediaColor.spectrumCyan"))
        XCTAssertFalse(accent.contains(#""green" : "0.353""#), "The accent must not retain the brass palette.")
        XCTAssertTrue(accent.contains(#""appearance" : "contrast""#))
        XCTAssertFalse(FileManager.default.fileExists(atPath: retiredAsset.path))
    }

    func testDefaultAccentUsesSoftNeutralSilverInsteadOfSharpBlue() throws {
        let assetURL = repositoryRoot.appending(
            path: "PrismediaShared/Resources/Brand.xcassets/PrismediaAccent.colorset/Contents.json"
        )
        let data = try Data(contentsOf: assetURL)
        let document = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let colors = try XCTUnwrap(document["colors"] as? [[String: Any]])
        let standard = try XCTUnwrap(colors.first { $0["appearances"] == nil })
        let color = try XCTUnwrap(standard["color"] as? [String: Any])
        let components = try XCTUnwrap(color["components"] as? [String: String])
        let red = try XCTUnwrap(Double(components["red"] ?? ""))
        let green = try XCTUnwrap(Double(components["green"] ?? ""))
        let blue = try XCTUnwrap(Double(components["blue"] ?? ""))
        let chroma = max(red, green, blue) - min(red, green, blue)

        XCTAssertGreaterThanOrEqual(red, 0.75)
        XCTAssertGreaterThanOrEqual(green, 0.75)
        XCTAssertGreaterThanOrEqual(blue, 0.75)
        XCTAssertLessThanOrEqual(red, 0.85)
        XCTAssertLessThanOrEqual(green, 0.85)
        XCTAssertLessThanOrEqual(blue, 0.85)
        XCTAssertLessThan(chroma, 0.04)
    }

    func testGenericFullPageSurfacesUseTheSharedScreenBackground() throws {
        let relativePaths = [
            "PrismediaShared/Features/Dashboard/DashboardView.swift",
            "PrismediaShared/Features/PlaybackStatistics/PlaybackStatisticsView.swift",
            "PrismediaShared/Features/Search/SearchHubView.swift",
            "PrismediaShared/Features/Administration/AdministrativeFilesView.swift",
            "PrismediaShared/Features/Identify/Components/IdentifySidebarList.swift",
            "PrismediaShared/Features/Request/RequestWorkspaceView.swift",
            "PrismediaShared/Features/Administration/AdministrativeSettingsView.swift",
            "PrismediaShared/App/Shell/PlaceholderSectionView.swift",
        ]

        let violations = try relativePaths.filter { path in
            try !sourceFile(path).contains(".prismediaScreenBackground()")
        }

        XCTAssertEqual(
            violations,
            [],
            "Generic page roots must reveal the shared spectral backdrop: \(violations)"
        )
    }

    func testBrowseTabUsesSearchRoleWithItsOwnVisibleSystemSearchField() throws {
        let shell = try sourceFile(
            "PrismediaShared/App/Shell/PrismediaShellView.swift"
        )
        let browse = try sourceFile(
            "PrismediaShared/Features/Search/SearchHubView.swift"
        )

        XCTAssertTrue(shell.contains("\"Browse\",\n                systemImage: \"square.grid.2x2\""))
        XCTAssertTrue(shell.contains("role: .search"))
        XCTAssertTrue(browse.contains(".navigationTitle(\"Browse\")"))
        XCTAssertTrue(
            browse.contains("placement: .navigationBarDrawer(displayMode: .always)")
        )
        XCTAssertFalse(browse.contains("sectionTitle(\"Browse\")"))
    }

    func testScreenBackgroundOwnsTheNavigationContainerSurface() throws {
        let source = try sourceFile(
            "PrismediaShared/DesignSystem/Modifiers/PrismediaScreenBackgroundModifier.swift"
        )

        XCTAssertTrue(source.contains(".containerBackground(for: .navigation)"))
        XCTAssertTrue(source.contains("PrismediaBackdrop()"))
        XCTAssertTrue(source.contains(".scrollContentBackground(.hidden)"))
    }

    @MainActor
    func testMusicBrowseBackdropWithoutArtworkUsesBaseBackground() throws {
        let backdrop = MusicBrowseBackdrop(
            artworkPath: nil,
            previewPath: nil,
            fallbackSeed: "Emerald Sessions",
            systemImage: "music.note"
        )
        .frame(width: 180, height: 180)
        .environment(\.colorScheme, .dark)
        .environment(PrismediaPreviewData.model())

        let renderer = ImageRenderer(content: backdrop)
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.cgImage)
        let pixel = try rgbaPixel(from: image, x: image.width / 2, y: image.height / 3)
        let channels = [Double(pixel.red), Double(pixel.green), Double(pixel.blue)]
        let normalizedChroma = (try XCTUnwrap(channels.max()) - (try XCTUnwrap(channels.min()))) / 255

        XCTAssertLessThan(
            normalizedChroma,
            0.05,
            "A detail without real artwork must keep the semantic base background."
        )
    }

    func testMusicDetailBackdropUsesTheSharedExtractedPaletteSurface() throws {
        let source = try sourceFile(
            "PrismediaShared/Features/Playback/Audio/Components/MusicBrowseBackdrop.swift"
        )
        let library = try sourceFile(
            "PrismediaShared/Features/Playback/Audio/Components/MusicLibraryView.swift"
        )

        XCTAssertTrue(source.contains("ArtworkPaletteSurface("))
        XCTAssertFalse(source.contains("RemotePosterImage("))
        XCTAssertFalse(library.contains("ArtworkPaletteSurface("))
    }

    func testArtworkPaletteBackdropCannotParticipateInContentSizing() throws {
        let source = try sourceFile(
            "PrismediaShared/UI/Components/ArtworkPaletteSurface.swift"
        )

        XCTAssertTrue(source.contains("content\n            .environment(\\.artworkPalette"))
        XCTAssertTrue(source.contains(".background {\n                backdrop"))
        XCTAssertFalse(source.contains("ZStack {\n            backdrop"))
    }

    func testPlaybackControlsUseArtworkPaletteAccentsWithTheSharedFallback() throws {
        let iOSNowPlaying = try sourceFile(
            "PrismediaShared/Features/Playback/Audio/Components/MusicNowPlayingView.swift"
        )
        let macNowPlaying = try sourceFile(
            "PrismediaShared/Features/Playback/Audio/Components/MacMusicNowPlayingView.swift"
        )
        let musicTimeline = try sourceFile(
            "PrismediaShared/Features/Playback/Audio/Components/MusicPlaybackTimeline.swift"
        )
        let volume = try sourceFile(
            "PrismediaShared/Infrastructure/PlatformAdapters/Playback/SystemVolumeSlider.swift"
        )
        let videoTimeline = try sourceFile(
            "PrismediaShared/Features/Playback/Video/Components/VideoPlaybackTimeline.swift"
        )
        let videoFilmstrip = try sourceFile(
            "PrismediaShared/Features/Playback/Video/Components/VideoFilmstripView.swift"
        )
        let videoPlayer = try sourceFile(
            "PrismediaShared/Features/Playback/Video/Components/PrismediaVideoPlayerView.swift"
        )

        XCTAssertTrue(iOSNowPlaying.contains("ArtworkPaletteSurface("))
        XCTAssertTrue(macNowPlaying.contains("ArtworkPaletteSurface("))
        XCTAssertTrue(musicTimeline.contains("@Environment(\\.artworkPrimaryAccent)"))
        XCTAssertTrue(musicTimeline.contains(".tint(artworkPrimaryAccent)"))
        XCTAssertTrue(volume.contains("@Environment(\\.artworkPrimaryAccent)"))
        XCTAssertTrue(volume.contains("uiView.tintColor = UIColor(artworkPrimaryAccent)"))

        for source in [videoTimeline, videoFilmstrip, videoPlayer] {
            XCTAssertTrue(source.contains("@Environment(\\.artworkPrimaryAccent)"))
        }
        XCTAssertFalse(videoTimeline.contains("PrismediaColor.accent"))
        XCTAssertFalse(videoFilmstrip.contains("PrismediaColor.accent"))
        XCTAssertFalse(videoPlayer.contains("PrismediaColor.accent"))
    }

    func testMusicBrowseScreensUseSemanticContentAndNativePlaybackControls() throws {
        let artist = try sourceFile(
            "PrismediaShared/Features/Playback/Audio/Components/MusicArtistDetailView.swift"
        )
        let album = try sourceFile(
            "PrismediaShared/Features/Playback/Audio/Components/MusicAlbumDetailView.swift"
        )
        let controls = try sourceFile(
            "PrismediaShared/Features/Playback/Audio/Components/MusicPlaybackButtons.swift"
        )

        XCTAssertTrue(artist.contains("MusicBrowseBackdrop("))
        XCTAssertFalse(artist.contains(".background(Color.black"))
        XCTAssertFalse(artist.contains(".foregroundStyle(.white)"))

        XCTAssertTrue(album.contains("MusicBrowseBackdrop("))
        XCTAssertFalse(album.contains("private var albumBackground"))
        XCTAssertFalse(album.contains(".background(.thinMaterial"))
        XCTAssertFalse(album.contains(".background(.white"))
        XCTAssertFalse(album.contains(".foregroundStyle(.white)"))
        XCTAssertFalse(album.contains(".foregroundStyle(.black)"))
        XCTAssertTrue(album.contains("PrismediaButton("))
        XCTAssertTrue(album.contains("variant: .prominent"))
        XCTAssertTrue(album.contains("form: .compactIcon"))
        XCTAssertFalse(album.contains(".buttonStyle(.glass"))

        XCTAssertFalse(controls.contains("Color(hex:"))
        XCTAssertFalse(controls.contains("Color.white"))
        XCTAssertFalse(controls.contains(".buttonStyle(.plain)"))
        XCTAssertTrue(controls.contains("PrismediaButton("))
        XCTAssertTrue(controls.contains("variant: .prominent"))
        XCTAssertTrue(controls.contains("form: .fill"))
        XCTAssertFalse(controls.contains(".buttonStyle(.glass"))
    }

    func testSharedCardsUseAnOpaqueSemanticContentSurface() throws {
        let source = try sourceFile(
            "PrismediaShared/DesignSystem/Modifiers/PrismediaCardModifier.swift"
        )

        XCTAssertTrue(source.contains("PrismediaColor.elevatedContentBackground"))
        XCTAssertTrue(source.contains("PrismediaColor.background"))
        XCTAssertFalse(source.contains("Material"))
        XCTAssertFalse(source.contains("material"))
    }

    func testStaticVideoStatusChipsUseSemanticCapsulesInsteadOfLiquidGlass() throws {
        let source = try sourceFile(
            "PrismediaShared/Features/Playback/Video/Components/VideoStatusChips.swift"
        )

        XCTAssertFalse(source.contains("GlassEffectContainer"))
        XCTAssertFalse(source.contains(".glassEffect"))
        XCTAssertTrue(source.contains("PrismediaColor.controlFill"))
        XCTAssertTrue(source.contains("overlaysVideo"))
    }

    @MainActor
    private func luminance(
        _ pixel: (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8)
    ) -> Double {
        let red = 0.2126 * Double(pixel.red)
        let green = 0.7152 * Double(pixel.green)
        let blue = 0.0722 * Double(pixel.blue)
        return (red + green + blue) / 255
    }

    private func normalizedChroma(
        _ pixel: (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8)
    ) -> Double {
        let channels = [Double(pixel.red), Double(pixel.green), Double(pixel.blue)]
        guard let minimum = channels.min(), let maximum = channels.max() else { return 0 }
        return (maximum - minimum) / 255
    }

    private func sourceFile(_ relativePath: String) throws -> String {
        try String(
            contentsOf: repositoryRoot.appending(path: relativePath),
            encoding: .utf8
        )
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func rgbaPixel(
        from image: CGImage,
        x: Int,
        y: Int
    ) throws -> (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        var pixel = [UInt8](repeating: 0, count: 4)
        let context = try XCTUnwrap(
            CGContext(
                data: &pixel,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.draw(
            image,
            in: CGRect(x: -x, y: y - image.height + 1, width: image.width, height: image.height)
        )
        return (pixel[0], pixel[1], pixel[2], pixel[3])
    }
}
