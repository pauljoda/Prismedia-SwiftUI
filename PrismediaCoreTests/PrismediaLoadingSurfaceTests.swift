import Foundation
import SwiftUI
import XCTest

@testable import PrismediaCore

final class PrismediaLoadingSurfaceTests: XCTestCase {
    @MainActor
    func testSharedLoadingSurfaceRendersAtTheViewportCenter() throws {
        let view = PrismediaLoadingView("Loading…")
            .frame(width: 320, height: 640, alignment: .top)
            .environment(\.colorScheme, .dark)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.cgImage)
        let bounds = try XCTUnwrap(alphaBounds(in: image))

        XCTAssertEqual(bounds.midY, CGFloat(image.height) / 2, accuracy: 32)
    }

    func testSharedLoadingSurfaceFillsAndCentersInItsViewport() throws {
        let source = try sourceFile(
            "PrismediaShared/UI/Components/PrismediaLoadingView.swift"
        )

        XCTAssertEqual(
            source.components(separatedBy: "Spacer()").count - 1,
            2,
            "The loading mark must stay vertically centered between equal flexible spacers."
        )
        XCTAssertTrue(source.contains(".frame(maxWidth: .infinity, maxHeight: .infinity)"))
    }

    func testBlockingLoadingStatesUseTheSharedPrismediaAnimation() throws {
        let relativePaths = [
            "PrismediaShared/App/PrismediaRootView.swift",
            "PrismediaShared/Features/Administration/AdministrativeFilesView.swift",
            "PrismediaShared/Features/Administration/AdministrativeIdentifyView.swift",
            "PrismediaShared/Features/Administration/AdministrativeJobsView.swift",
            "PrismediaShared/Features/Administration/AdministrativePluginsView.swift",
            "PrismediaShared/Features/Administration/AdministrativeRequestView.swift",
            "PrismediaShared/Features/Administration/AdministrativeSettingsView.swift",
            "PrismediaShared/Features/Administration/Components/AdministrativeFileBrowserView.swift",
            "PrismediaShared/Features/Dashboard/DashboardView.swift",
            "PrismediaShared/Features/EntityDetail/EntityDetailView.swift",
            "PrismediaShared/Features/EntityGrid/EntityGridView.swift",
            "PrismediaShared/Features/EntityGrid/MediaListView.swift",
            "PrismediaShared/Features/Identify/Components/IdentifyKindBrowseView.swift",
            "PrismediaShared/Features/Identify/Components/IdentifyQueueView.swift",
            "PrismediaShared/Features/Playback/Audio/Components/MusicLibraryView.swift",
            "PrismediaShared/Features/PlaybackStatistics/PlaybackStatisticsView.swift",
            "PrismediaShared/Features/Reader/ComicReaderView.swift",
            "PrismediaShared/Features/Reader/Components/EPUBSearchPanel.swift",
            "PrismediaShared/Features/Reader/Components/ReadiumEPUBReaderView.swift",
            "PrismediaShared/Features/Reader/EPUBReaderView.swift",
            "PrismediaShared/Features/Reader/PDFReaderView.swift",
            "PrismediaShared/Features/Request/Components/RequestAcquisitionSettingsView.swift",
            "PrismediaShared/Features/Request/Components/RequestReviewView.swift",
            "PrismediaShared/Features/RequestActivity/RequestActivityAcquisitionDetailView.swift",
            "PrismediaShared/Features/RequestActivity/RequestActivitySurface.swift",
            "PrismediaShared/Features/Search/SearchHubView.swift",
            "PrismediaShared/Features/Television/TVHomeView.swift",
            "PrismediaShared/UI/Components/AddToCollectionSheet.swift",
        ]

        let violations = try relativePaths.filter { path in
            try !sourceFile(path).contains("PrismediaLoadingView(")
        }

        XCTAssertEqual(
            violations,
            [],
            "Blocking loading states must share the branded loading surface: \(violations)"
        )
    }

    func testMusicAlbumLoadingKeepsItsArtworkAtmosphereAndUsesTheSharedAnimation() throws {
        let source = try sourceFile(
            "PrismediaShared/Features/Playback/Audio/Components/MusicAlbumLoadingView.swift"
        )

        XCTAssertTrue(source.contains("MusicBrowseBackdrop("))
        XCTAssertTrue(source.contains("PrismediaLoadingMark()"))
        XCTAssertFalse(source.contains("ProgressView()"))
    }

    func testIdentifyUsesFullSpaceLoadingOnlyWithoutRetainedContent() throws {
        let browse = try sourceFile(
            "PrismediaShared/Features/Identify/Components/IdentifyKindBrowseView.swift"
        )
        let queue = try sourceFile(
            "PrismediaShared/Features/Identify/Components/IdentifyQueueView.swift"
        )

        XCTAssertTrue(browse.contains("session.isBrowsing && session.browseItems.isEmpty"))
        XCTAssertTrue(browse.contains("else if session.isBrowsing"))
        XCTAssertTrue(queue.contains("session.isLoading && session.queue.isEmpty"))
        XCTAssertTrue(queue.contains("else if session.isLoading"))
    }

    func testScopedProgressKeepsNativeFeedback() throws {
        let button = try sourceFile(
            "PrismediaShared/DesignSystem/Components/PrismediaButton.swift"
        )
        let entityGrid = try sourceFile(
            "PrismediaShared/Features/EntityGrid/EntityGridView.swift"
        )
        let downloads = try sourceFile(
            "PrismediaShared/Features/RequestActivity/Components/RequestActivityDownloadRow.swift"
        )

        XCTAssertTrue(button.contains("ProgressView()"), "Button work needs compact native feedback.")
        XCTAssertTrue(entityGrid.contains("ProgressView(\"Loading more…\")"))
        XCTAssertTrue(downloads.contains("ProgressView(value:"), "Downloads need determinate progress.")
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

    private func alphaBounds(in image: CGImage) throws -> CGRect? {
        let bytesPerPixel = 4
        let bytesPerRow = image.width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: bytesPerRow * image.height)
        let context = try XCTUnwrap(
            CGContext(
                data: &pixels,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

        var minimumX = image.width
        var minimumY = image.height
        var maximumX = -1
        var maximumY = -1
        for y in 0..<image.height {
            for x in 0..<image.width {
                let alpha = pixels[y * bytesPerRow + x * bytesPerPixel + 3]
                guard alpha > 8 else { continue }
                minimumX = min(minimumX, x)
                minimumY = min(minimumY, y)
                maximumX = max(maximumX, x)
                maximumY = max(maximumY, y)
            }
        }
        guard maximumX >= minimumX, maximumY >= minimumY else { return nil }
        return CGRect(
            x: minimumX,
            y: minimumY,
            width: maximumX - minimumX + 1,
            height: maximumY - minimumY + 1
        )
    }
}
