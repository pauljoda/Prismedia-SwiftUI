import Foundation
import SwiftUI
import XCTest

@testable import PrismediaCore

final class SharedPresentationRegressionTests: XCTestCase {
    @MainActor
    func testPinnedSectionHeaderSurfaceRemainsVisibleInTheFixedDarkAppearance() throws {
        let dark = try sampledBackgroundLuminance(for: .dark)

        XCTAssertGreaterThan(dark, 0.01, "The dark semantic surface must not collapse to pure black.")
    }

    func testMusicLibraryUsesTheSharedAdaptivePinnedSectionHeader() throws {
        let source = try sourceFile(
            "PrismediaShared/Features/Playback/Audio/Components/MusicLibraryView.swift"
        )

        XCTAssertTrue(source.contains("PrismediaPinnedSectionHeader(title: section.title)"))
        XCTAssertFalse(
            source.contains(".background(.regularMaterial)"),
            "Alphabet headers are content, so they need a semantic adaptive surface instead of material."
        )
    }

    func testEntityDetailRailsResolveParentAwareThumbnailPresentation() throws {
        let source = try sourceFile(
            "PrismediaShared/Features/EntityDetail/Components/EntityDetailSectionPanel.swift"
        )

        XCTAssertTrue(
            source.contains("relationshipCardWidth(for: item.thumbnailPresentationKind)"),
            "Non-tv rails must size movie-owned videos with the same poster presentation as shared and tvOS cards."
        )
        XCTAssertFalse(source.contains("relationshipCardWidth(for: item.kind)"))
    }

    func testDashboardRailMeasuresEveryMixedAspectRatioCard() throws {
        let source = try sourceFile(
            "PrismediaShared/Features/Dashboard/Components/DashboardShelfView.swift"
        )

        XCTAssertTrue(
            source.contains("HStack(alignment: .top, spacing: PrismediaSpacing.small)"),
            "Dashboard rails must measure every card so their height includes tall poster artwork."
        )
        XCTAssertFalse(
            source.contains("LazyHStack(alignment: .top, spacing: PrismediaSpacing.small)"),
            "A lazy horizontal stack can size the rail from a shorter wide card and clip taller cards."
        )
    }

    func testDashboardHeroUsesFullWidthWidescreenArtworkBelowTheTopBar() throws {
        let carousel = try sourceFile(
            "PrismediaShared/Features/Dashboard/Components/DashboardHeroCarouselView.swift"
        )
        let artwork = try sourceFile(
            "PrismediaShared/Features/Dashboard/Components/DashboardHeroArtworkView.swift"
        )
        let continuation = try sourceFile(
            "PrismediaShared/Features/Dashboard/Components/DashboardHeroArtworkContinuationView.swift"
        )
        let dashboard = try sourceFile(
            "PrismediaShared/Features/Dashboard/DashboardView.swift"
        )

        XCTAssertTrue(carousel.contains("accessibilityReduceMotion"))
        XCTAssertTrue(artwork.contains("aspectRatio(16.0 / 9.0, contentMode: .fit)"))
        XCTAssertTrue(artwork.contains(".frame(maxWidth: .infinity)"))
        XCTAssertTrue(artwork.contains(".backgroundExtensionEffect()"))
        XCTAssertTrue(continuation.contains(".backgroundExtensionEffect()"))
        XCTAssertTrue(dashboard.contains(".toolbarBackground(.hidden, for: .navigationBar)"))
        XCTAssertFalse(
            dashboard.contains(".ignoresSafeArea(edges: .top)"),
            "The artwork must start below the top bar; its background extension alone should fill the safe area."
        )
    }

    func testDashboardHeroPagesArtworkAndControlsAsOneCard() throws {
        let carousel = try sourceFile(
            "PrismediaShared/Features/Dashboard/Components/DashboardHeroCarouselView.swift"
        )
        let page = try sourceFile(
            "PrismediaShared/Features/Dashboard/Components/DashboardHeroPageView.swift"
        )
        let continuation = try sourceFile(
            "PrismediaShared/Features/Dashboard/Components/DashboardHeroArtworkContinuationView.swift"
        )
        let content = try sourceFile(
            "PrismediaShared/Features/Dashboard/Components/DashboardHeroContentView.swift"
        )

        XCTAssertTrue(carousel.contains("ScrollView(.horizontal)"))
        XCTAssertTrue(carousel.contains("LazyHStack(spacing: 0)"))
        XCTAssertTrue(carousel.contains("DashboardHeroPageView("))
        XCTAssertTrue(carousel.contains(".scrollTargetLayout()"))
        XCTAssertTrue(carousel.contains(".scrollTargetBehavior(.paging)"))
        XCTAssertTrue(carousel.contains(".scrollPosition(id: $selectedItemID)"))
        XCTAssertTrue(
            carousel.contains(".contentMargins(.horizontal, 0, for: .scrollContent)"),
            "Automatic horizontal scroll margins must not shift a full-viewport hero page offscreen."
        )
        XCTAssertTrue(page.contains("VStack(spacing: 0)"))
        XCTAssertTrue(page.contains("DashboardHeroArtworkView("))
        XCTAssertTrue(page.contains("DashboardHeroContentView("))
        XCTAssertTrue(continuation.contains("DashboardHeroSceneView("))
        XCTAssertTrue(continuation.contains(".blur(radius:"))
        XCTAssertTrue(carousel.contains("DashboardHeroProgressIndicator("))
        XCTAssertFalse(content.contains("DashboardHeroProgressIndicator("))
    }

    func testDashboardHeroOwnsViewportAndConstrainsTitleAndDetailsAction() throws {
        let carousel = try sourceFile(
            "PrismediaShared/Features/Dashboard/Components/DashboardHeroCarouselView.swift"
        )
        let artwork = try sourceFile(
            "PrismediaShared/Features/Dashboard/Components/DashboardHeroArtworkView.swift"
        )
        let content = try sourceFile(
            "PrismediaShared/Features/Dashboard/Components/DashboardHeroContentView.swift"
        )
        let actions = try sourceFile(
            "PrismediaShared/Features/Dashboard/Components/DashboardHeroActionsView.swift"
        )
        let dashboard = try sourceFile(
            "PrismediaShared/Features/Dashboard/DashboardView.swift"
        )

        XCTAssertTrue(carousel.contains("let viewportWidth: CGFloat"))
        XCTAssertTrue(carousel.contains(".frame(width: viewportWidth)"))
        XCTAssertFalse(carousel.contains(".containerRelativeFrame(.horizontal)"))
        XCTAssertTrue(carousel.contains(".accessibilityElement(children: .contain)"))
        XCTAssertTrue(dashboard.contains("GeometryReader { viewport in"))
        XCTAssertTrue(dashboard.contains("viewportWidth: viewport.size.width"))
        XCTAssertTrue(
            dashboard.contains(".frame(width: viewport.size.width, alignment: .leading)")
        )
        XCTAssertTrue(artwork.contains(".clipped()"))
        XCTAssertTrue(content.contains(".minimumScaleFactor(0.72)"))
        XCTAssertTrue(content.contains(".allowsTightening(true)"))
        XCTAssertTrue(content.contains(".accessibilityIdentifier(\"dashboard.hero.title\")"))
        XCTAssertTrue(
            content.contains("width: min(viewportWidth, PrismediaLayout.readableContentWidth)")
        )
        let padding = try XCTUnwrap(content.range(of: ".padding(.horizontal"))
        let readableWidth = try XCTUnwrap(
            content.range(of: "width: min(viewportWidth, PrismediaLayout.readableContentWidth)")
        )
        XCTAssertLessThan(
            padding.lowerBound,
            readableWidth.lowerBound,
            "The readable-width frame must include horizontal padding instead of adding it outside the viewport."
        )

        XCTAssertTrue(actions.contains("systemImage: \"info.circle\""))
        XCTAssertFalse(actions.contains("systemImage: \"plus\""))
    }

    func testImageViewerPagesUseTheMeasuredFullscreenViewport() throws {
        let source = try sourceFile(
            "PrismediaShared/Features/ImageViewer/EntityImageViewerView.swift"
        )

        XCTAssertTrue(source.contains("GeometryReader { viewport in"))
        XCTAssertTrue(source.contains("pager(viewportSize: viewport.size)"))
        XCTAssertTrue(
            source.contains(
                ".frame(width: viewportSize.width, height: viewportSize.height)"
            )
        )
        XCTAssertFalse(source.contains(".containerRelativeFrame([.horizontal, .vertical])"))
    }

    func testImageViewerLeavesToolbarBackingToNativeLiquidGlass() throws {
        let viewerSource = try sourceFile(
            "PrismediaShared/Features/ImageViewer/EntityImageViewerView.swift"
        )
        let toolbarSource = try sourceFile(
            "PrismediaShared/Features/ImageViewer/Components/EntityImageViewerToolbar.swift"
        )

        XCTAssertTrue(
            viewerSource.contains(
                ".toolbarBackground(.hidden, for: .navigationBar, .bottomBar)"
            )
        )
        XCTAssertFalse(toolbarSource.contains("LinearGradient"))
        XCTAssertFalse(toolbarSource.contains(".background("))
    }

    func testLandscapeThumbnailUsesOneFeatheredArtworkSurface() throws {
        let source = try sourceFile(
            "PrismediaShared/UI/Components/EntityThumbnailLandscapeCardView.swift"
        )

        XCTAssertTrue(source.contains("ZStack(alignment: .top)"))
        XCTAssertTrue(source.contains("continuationArtwork"))
        XCTAssertTrue(source.contains(".frame(width: width, height: cardHeight)"))
        XCTAssertTrue(source.contains(".scaleEffect(1.08)"))
        XCTAssertTrue(source.contains(".mask(artworkFade)"))
        XCTAssertTrue(source.contains("#if os(tvOS)"))
        XCTAssertTrue(source.contains("maxPixelSize: 512"))
        XCTAssertTrue(source.contains("private var paletteLoadingEnabled"))
        XCTAssertFalse(
            source.contains("VStack(spacing: 0)"),
            "Artwork and metadata must blend in one card surface instead of stacking as distinct sections."
        )
    }

    func testLandscapeThumbnailProgressUsesArtworkAccentAndKeepsMetadataClear() throws {
        let landscape = try sourceFile(
            "PrismediaShared/UI/Components/EntityThumbnailLandscapeCardView.swift"
        )
        let artwork = try sourceFile(
            "PrismediaShared/UI/Components/EntityThumbnailArtworkView.swift"
        )
        let paletteLoader = try sourceFile(
            "PrismediaShared/UI/Modifiers/ArtworkPaletteTaskModifier.swift"
        )

        XCTAssertTrue(paletteLoader.contains("environment.artworkPaletteLoader.palette"))
        XCTAssertTrue(landscape.contains(".prismediaArtworkPalette("))
        XCTAssertTrue(artwork.contains(".prismediaArtworkPalette("))
        XCTAssertTrue(landscape.contains("artworkPalette?.primary.color ?? PrismediaColor.accent"))
        XCTAssertTrue(artwork.contains("artworkPalette?.primary.color ?? PrismediaColor.accent"))
        XCTAssertTrue(landscape.contains("private var metadataBottomPadding"))
        XCTAssertTrue(landscape.contains(".padding(.bottom, metadataBottomPadding)"))
        XCTAssertTrue(landscape.contains(".fill(progressTint)"))
        XCTAssertTrue(artwork.contains(".fill(progressTint)"))
    }

    func testLandscapeThumbnailKeepsTitleFullWidthAndActionAlignedWithChipRow() throws {
        let landscape = try sourceFile(
            "PrismediaShared/UI/Components/EntityThumbnailLandscapeCardView.swift"
        )
        let navigation = try sourceFile(
            "PrismediaShared/UI/Components/EntityThumbnailNavigationSurface.swift"
        )

        XCTAssertGreaterThanOrEqual(
            landscape.components(separatedBy: ".lineLimit(2)").count - 1,
            3
        )
        XCTAssertGreaterThanOrEqual(
            landscape.components(
                separatedBy: ".frame(maxWidth: .infinity, alignment: .leading)"
            ).count - 1,
            3
        )
        XCTAssertTrue(landscape.contains("metadataChipRow(limit:"))
        XCTAssertTrue(landscape.contains("metadataActionTrailingPadding"))
        XCTAssertFalse(landscape.contains(".padding(.trailing, metadataTrailingPadding)"))
        XCTAssertTrue(navigation.contains("minHeight: PrismediaLayout.minimumHitTarget"))
        XCTAssertTrue(navigation.contains("alignment: .bottomTrailing"))
        XCTAssertFalse(navigation.contains("contextMenu\n            .glassEffect"))
    }

    func testTVSeasonsHeroKeepsItsOverlayStaticDuringArtworkChanges() throws {
        let background = try sourceFile(
            "PrismediaShared/Features/Television/Components/TVSeasonsHeroBackground.swift"
        )
        let copy = try sourceFile(
            "PrismediaShared/Features/Television/Components/TVSeasonsHeroCopy.swift"
        )
        let preview = try sourceFile(
            "PrismediaShared/Features/Television/Components/TVEpisodePreviewBackdrop.swift"
        )

        XCTAssertTrue(background.contains("TVEpisodePreviewBackdrop("))
        XCTAssertFalse(background.contains("selectedEpisodeDetail"))
        XCTAssertFalse(background.contains(".transition("))
        XCTAssertFalse(background.contains(".animation("))
        XCTAssertFalse(background.contains(".id("))
        XCTAssertTrue(preview.contains("retainsCurrentImageWhileLoading: true"))
        XCTAssertTrue(preview.contains("TVEpisodePreviewFrameSampler.sample"))
        XCTAssertTrue(preview.contains(".easeInOut(duration: 0.4)"))

        XCTAssertTrue(copy.contains(".frame(minHeight: 250, alignment: .bottomLeading)"))
        XCTAssertTrue(copy.contains("lineLimit(2, reservesSpace: true)"))
        XCTAssertTrue(copy.contains("TVEpisodeDescriptionView("))
        XCTAssertTrue(copy.contains("length / 3"))
        XCTAssertFalse(copy.contains("selectedEpisodeDetail"))
    }

    func testTVRailsAreLazyAndDoNotExposeThumbnailMenus() throws {
        let episodeRail = try sourceFile(
            "PrismediaShared/Features/Television/Components/TVEpisodeRail.swift"
        )
        let homeShelf = try sourceFile(
            "PrismediaShared/Features/Television/Components/TVHomeShelfSection.swift"
        )
        let interaction = try sourceFile(
            "PrismediaShared/UI/Support/EntityThumbnailInteractionPolicy.swift"
        )
        let boundaryDirection = try sourceFile(
            "PrismediaShared/Features/Television/Models/TVSeasonBoundaryDirection.swift"
        )

        XCTAssertTrue(episodeRail.contains("LazyHStack(alignment: .top"))
        XCTAssertTrue(homeShelf.contains("LazyHStack(alignment: .top"))
        XCTAssertTrue(interaction.contains("#if os(tvOS)"))
        XCTAssertTrue(interaction.contains("showsContextMenu = false"))
        XCTAssertTrue(boundaryDirection.contains("tv.seasons-detail.previous-season"))
        XCTAssertTrue(boundaryDirection.contains("tv.seasons-detail.next-season"))

        let picker = try sourceFile(
            "PrismediaShared/Features/Television/Components/TVSeasonPicker.swift"
        )
        XCTAssertTrue(picker.contains(".tvSeasonSelectionTint(isSelected)"))
        XCTAssertFalse(picker.contains(": .clear"))
        XCTAssertFalse(picker.contains("checkmark.circle.fill"))
    }

    private func sourceFile(_ relativePath: String) throws -> String {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appending(path: relativePath),
            encoding: .utf8
        )
    }

    @MainActor
    private func sampledBackgroundLuminance(for colorScheme: ColorScheme) throws -> Double {
        let header = PrismediaPinnedSectionHeader(title: "A")
            .frame(width: 220)
            .environment(\.colorScheme, colorScheme)
        let renderer = ImageRenderer(content: header)
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.cgImage)
        let pixel = try rgbaPixel(from: image, x: image.width - 4, y: image.height / 2)
        let weightedChannels =
            0.2126 * Double(pixel.red)
            + 0.7152 * Double(pixel.green)
            + 0.0722 * Double(pixel.blue)
        return weightedChannels / 255
    }

    private func rgbaPixel(
        from image: CGImage,
        x: Int,
        y: Int
    ) throws -> (red: UInt8, green: UInt8, blue: UInt8) {
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
        return (pixel[0], pixel[1], pixel[2])
    }
}
