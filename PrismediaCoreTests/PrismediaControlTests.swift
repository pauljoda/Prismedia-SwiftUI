import Foundation
import XCTest

@testable import PrismediaCore

final class PrismediaControlTests: XCTestCase {
    func testButtonVariantsDescribeTheirNativePresentation() {
        XCTAssertFalse(PrismediaButtonVariant.standard.isProminent)
        XCTAssertFalse(PrismediaButtonVariant.standard.isDestructive)

        XCTAssertTrue(PrismediaButtonVariant.prominent.isProminent)
        XCTAssertFalse(PrismediaButtonVariant.prominent.isDestructive)

        XCTAssertFalse(PrismediaButtonVariant.destructive.isProminent)
        XCTAssertTrue(PrismediaButtonVariant.destructive.isDestructive)
    }

    func testButtonFormsDescribeLayoutWithoutFeatureSpecificMetrics() {
        XCTAssertFalse(PrismediaButtonForm.automatic.fillsAvailableWidth)
        XCTAssertFalse(PrismediaButtonForm.automatic.isCompactIcon)

        XCTAssertTrue(PrismediaButtonForm.fill.fillsAvailableWidth)
        XCTAssertFalse(PrismediaButtonForm.fill.isCompactIcon)

        XCTAssertFalse(PrismediaButtonForm.compactIcon.fillsAvailableWidth)
        XCTAssertTrue(PrismediaButtonForm.compactIcon.isCompactIcon)
    }

    func testControlSurfacesDistinguishFloatingGlassFromEmbeddedControls() {
        XCTAssertTrue(PrismediaControlSurface.floating.usesGlass)
        XCTAssertFalse(PrismediaControlSurface.embedded.usesGlass)
    }

    func testSharedButtonsDefaultToClearGlassAndPermitExplicitPrimaryTint() throws {
        let buttonPath = "PrismediaShared/DesignSystem/Components/PrismediaButton.swift"
        let buttonSource = try sourceFile(buttonPath)

        XCTAssertTrue(buttonSource.contains(".buttonStyle(.glass(.clear))"), buttonPath)
        XCTAssertFalse(buttonSource.contains("PrismediaButtonBorderBeam("), buttonPath)
        XCTAssertTrue(buttonSource.contains(".buttonStyle(.glassProminent)"), buttonPath)
        XCTAssertTrue(buttonSource.contains(".tint(primaryTint)"), buttonPath)
        XCTAssertFalse(buttonSource.contains(".buttonStyle(.borderedProminent)"), buttonPath)

        let tvPlaybackPath =
            "PrismediaShared/Features/Playback/Video/Components/VideoEntityPlaybackView.swift"
        let tvPlaybackSource = try sourceFile(tvPlaybackPath)

        XCTAssertFalse(tvPlaybackSource.contains("PrismediaButtonBorderBeam("), tvPlaybackPath)
        XCTAssertTrue(tvPlaybackSource.contains(".buttonStyle(.glass(.clear))"), tvPlaybackPath)
        XCTAssertFalse(tvPlaybackSource.contains(".buttonStyle(.glassProminent)"), tvPlaybackPath)

        let videoPlayerPath =
            "PrismediaShared/Features/Playback/Video/Components/PrismediaVideoPlayerView.swift"
        let videoPlayerSource = try sourceFile(videoPlayerPath)

        XCTAssertTrue(videoPlayerSource.contains(".buttonStyle(.glass(.clear))"), videoPlayerPath)
        XCTAssertFalse(videoPlayerSource.contains("PrismediaButtonBorderBeam("), videoPlayerPath)
        XCTAssertFalse(videoPlayerSource.contains(".regular.tint(prominent"), videoPlayerPath)

        let beamPath =
            "PrismediaShared/DesignSystem/Components/PrismediaButtonBorderBeam.swift"
        let beamSource = try sourceFile(beamPath)

        XCTAssertFalse(
            beamSource.contains("TimelineView("),
            "Keep TimelineView out of the beam's Xcode 27 Preview metadata graph: \(beamPath)"
        )
        XCTAssertTrue(
            beamSource.contains("@State private var animationProgress"),
            beamPath
        )
        XCTAssertTrue(beamSource.contains("animationDuration: TimeInterval = 600"), beamPath)
        XCTAssertTrue(
            beamSource.contains("detailAngle = Angle.degrees(-20 + progress * 360)"),
            beamPath
        )
        XCTAssertTrue(
            beamSource.contains("hazeAngle = Angle.degrees(140 + progress * 360)"),
            beamPath
        )
        XCTAssertTrue(beamSource.contains(".linear(duration: Self.animationDuration)"), beamPath)
        XCTAssertFalse(beamSource.contains(".easeInOut(duration:"), beamPath)
        XCTAssertTrue(beamSource.contains("hazeSpectrumGradient"), beamPath)
        XCTAssertFalse(
            beamSource.contains(".init(color: .clear"),
            "The spectrum must glow around the full perimeter: \(beamPath)"
        )
        for closedSeamStop in [
            ".init(color: PrismediaColor.spectrumCyan, location: 0)",
            ".init(color: PrismediaColor.spectrumCyan, location: 1)",
            ".init(color: PrismediaColor.spectrumMagenta, location: 0)",
            ".init(color: PrismediaColor.spectrumMagenta, location: 1)",
            ".init(color: PrismediaColor.textPrimary.opacity(0.3), location: 0)",
            ".init(color: PrismediaColor.textPrimary.opacity(0.3), location: 1)",
            ".init(color: PrismediaColor.textPrimary.opacity(0.42), location: 0)",
            ".init(color: PrismediaColor.textPrimary.opacity(0.42), location: 1)",
        ] {
            XCTAssertTrue(beamSource.contains(closedSeamStop), beamPath)
        }
        XCTAssertTrue(beamSource.contains(".repeatForever(autoreverses: false)"), beamPath)
        XCTAssertTrue(
            beamSource.contains(".onChange(of: pausesAnimation, initial: true)"),
            beamPath
        )
        XCTAssertTrue(beamSource.contains("transaction.disablesAnimations = true"), beamPath)
        XCTAssertTrue(beamSource.contains("accessibilityReduceMotion"), beamPath)
        XCTAssertTrue(beamSource.contains("accessibilityDifferentiateWithoutColor"), beamPath)
        XCTAssertTrue(beamSource.contains("AngularGradient("), beamPath)
        XCTAssertTrue(beamSource.contains(".mask {"), beamPath)
        XCTAssertTrue(beamSource.contains(".allowsHitTesting(false)"), beamPath)
        XCTAssertTrue(beamSource.contains(".accessibilityHidden(true)"), beamPath)
    }

    func testFeatureTextInputsUseTheSharedVisualStyle() throws {
        for path in [
            "PrismediaShared/Features/Authentication/SignInView.swift",
            "PrismediaShared/Features/PluginDiscovery/Components/PluginSearchFieldControl.swift",
            "PrismediaShared/Features/Reader/Components/PDFReaderSearchPanel.swift",
            "PrismediaShared/Features/Administration/AdministrativeRequestView.swift",
            "PrismediaShared/Features/Administration/Components/AdministrativeSettingControl.swift",
            "PrismediaShared/Features/EntityDetail/Components/EntityTranscriptView.swift",
        ] {
            let source = try sourceFile(path)
            XCTAssertTrue(source.contains(".prismediaTextInputStyle("), path)
            XCTAssertFalse(source.contains(".textFieldStyle(.roundedBorder)"), path)
        }
    }

    func testReadersShareNativePagingAndCloseToolbarControls() throws {
        let pagingPath =
            "PrismediaShared/Features/Reader/Components/ReaderPageNavigationToolbar.swift"
        let pagingSource = try sourceFile(pagingPath)
        XCTAssertTrue(pagingSource.contains("ToolbarContent"), pagingPath)
        XCTAssertTrue(pagingSource.contains("ToolbarItemGroup"), pagingPath)
        XCTAssertTrue(pagingSource.contains("placement: .status"), pagingPath)
        XCTAssertFalse(pagingSource.contains(".glassEffect("), pagingPath)

        let closePath = "PrismediaShared/Features/Reader/Components/ReaderCloseButton.swift"
        let closeSource = try sourceFile(closePath)
        XCTAssertTrue(closeSource.contains("struct ReaderCloseButton: View"), closePath)

        for path in [
            "PrismediaShared/Features/Reader/Components/ComicReaderToolbar.swift",
            "PrismediaShared/Features/Reader/Components/ReadiumEPUBReaderToolbar.swift",
            "PrismediaShared/Features/Reader/PDFReaderView.swift",
        ] {
            let source = try sourceFile(path)
            XCTAssertTrue(source.contains("ReaderCloseButton("), path)
        }

        for path in [
            "PrismediaShared/Features/Reader/ComicReaderView.swift",
            "PrismediaShared/Features/Reader/Components/ReadiumEPUBReaderView.swift",
            "PrismediaShared/Features/Reader/PDFReaderView.swift",
        ] {
            let source = try sourceFile(path)
            XCTAssertTrue(source.contains("ReaderPageNavigationToolbar("), path)
        }

        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath:
                    repositoryRoot
                    .appending(path: "PrismediaShared/Features/Reader/Components/ComicReaderControls.swift")
                    .path
            )
        )
    }

    func testEPUBReaderChromeUsesGroupedNativeToolbars() throws {
        let path = "PrismediaShared/Features/Reader/Components/ReadiumEPUBReaderToolbar.swift"
        let source = try sourceFile(path)
        XCTAssertTrue(source.contains("ToolbarContent"), path)
        XCTAssertTrue(source.contains("ToolbarItemGroup"), path)
        XCTAssertTrue(source.contains("ToolbarSpacer(.fixed"), path)
        XCTAssertFalse(source.contains("PrismediaButton("), path)
        XCTAssertFalse(source.contains(".glassEffect("), path)
    }

    func testImageViewerChromeUsesNativeToolbars() throws {
        let viewerPath = "PrismediaShared/Features/ImageViewer/EntityImageViewerView.swift"
        let viewerSource = try sourceFile(viewerPath)
        XCTAssertTrue(viewerSource.contains("EntityImageViewerToolbar("), viewerPath)
        XCTAssertTrue(viewerSource.contains(".navigationBarBackButtonHidden(true)"), viewerPath)
        XCTAssertFalse(viewerSource.contains("EntityImageViewerChrome("), viewerPath)

        let toolbarPath =
            "PrismediaShared/Features/ImageViewer/Components/EntityImageViewerToolbar.swift"
        let toolbarSource = try sourceFile(toolbarPath)
        XCTAssertTrue(toolbarSource.contains("ToolbarContent"), toolbarPath)
        XCTAssertTrue(toolbarSource.contains("placement: .cancellationAction"), toolbarPath)
        XCTAssertTrue(toolbarSource.contains("placement: .primaryAction"), toolbarPath)
        XCTAssertFalse(toolbarSource.contains("PrismediaButton("), toolbarPath)
        XCTAssertFalse(toolbarSource.contains("GlassEffectContainer"), toolbarPath)

        for path in [
            "PrismediaShared/Features/ImageViewer/Components/EntityImageZoomView.swift",
            "PrismediaShared/Features/ImageViewer/Components/EntityImageVideoView.swift",
            "PrismediaShared/Features/ImageViewer/Components/EntityAnimatedImageView.swift",
        ] {
            let source = try sourceFile(path)
            XCTAssertTrue(source.contains("ToolbarItem"), path)
            XCTAssertFalse(source.contains("PrismediaButton("), path)
            XCTAssertFalse(source.contains("GlassEffectContainer"), path)
        }
    }

    func testLegacyControlImplementationsWereRemoved() {
        for path in [
            "PrismediaShared/UI/Components/PrismediaGlassButton.swift",
            "PrismediaShared/UI/Components/ProgressActionButtonStyle.swift",
            "PrismediaShared/UI/Models/ProgressActionButtonProminence.swift",
        ] {
            XCTAssertFalse(FileManager.default.fileExists(atPath: repositoryRoot.appending(path: path).path))
        }
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
}
