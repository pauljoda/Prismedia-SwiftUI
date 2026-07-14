import Foundation
import XCTest

@testable import PrismediaCore

final class EntityDetailCompositionTests: XCTestCase {
    func testArtworkAtmosphereBelongsToTheWholeDetailInsteadOfEndingWithTheHeroBlock() throws {
        let detailView = try sourceFile(
            "PrismediaShared/Features/EntityDetail/EntityDetailView.swift"
        )
        let artworkSurface = try sourceFile(
            "PrismediaShared/Features/EntityDetail/Components/EntityDetailArtworkSurface.swift"
        )
        let heroInformation = try sourceFile(
            "PrismediaShared/Features/EntityDetail/Components/EntityDetailHeroInformationView.swift"
        )
        let hero = try sourceFile(
            "PrismediaShared/Features/EntityDetail/Components/EntityDetailHeroView.swift"
        )
        let videoPoster = try sourceFile(
            "PrismediaShared/Features/Playback/Video/Components/VideoPlaybackPosterView.swift"
        )

        XCTAssertTrue(detailView.contains("EntityDetailHeroArtworkPolicy.atmospherePath"))
        XCTAssertFalse(artworkSurface.contains(".clipped()"))
        XCTAssertFalse(heroInformation.contains("EntityDetailArtworkContinuationView"))
        XCTAssertFalse(heroInformation.contains(".background"))
        XCTAssertTrue(hero.contains(".mask {"))
        XCTAssertTrue(hero.contains("Color.clear"))
        XCTAssertTrue(videoPoster.contains("private var extendedArtwork"))
        XCTAssertTrue(videoPoster.contains(".mask {"))
        XCTAssertTrue(videoPoster.contains("Color.clear"))
    }

    func testTopDetailCompositionKeepsTheEntityTitle() throws {
        let header = try sourceFile(
            "PrismediaShared/Features/EntityDetail/Components/EntityDetailHeaderView.swift"
        )
        let identity = try sourceFile(
            "PrismediaShared/Features/EntityDetail/Components/EntityDetailIdentityView.swift"
        )

        XCTAssertTrue(header.contains("EntityDetailIdentityView("))
        XCTAssertTrue(identity.contains("Text(presentation.detail.title)"))
    }

    func testLoadedTitleAlsoOrientsTheTransparentNavigationToolbar() throws {
        let detailView = try sourceFile(
            "PrismediaShared/Features/EntityDetail/EntityDetailView.swift"
        )

        XCTAssertTrue(detailView.contains(".navigationTitle(navigationTitle)"))
        XCTAssertTrue(detailView.contains("private var navigationTitle: String"))
        XCTAssertTrue(detailView.contains(".toolbarBackground(.hidden, for: .navigationBar)"))
    }

    func testMaintenanceActionsMoveIntoOneNativeToolbarOverflowMenu() throws {
        let detailView = try sourceFile(
            "PrismediaShared/Features/EntityDetail/EntityDetailView.swift"
        )
        let toolbarMenu = try sourceFile(
            "PrismediaShared/Features/EntityDetail/Components/EntityDetailToolbarMenu.swift"
        )
        let albumDetail = try sourceFile(
            "PrismediaShared/Features/Playback/Audio/Components/MusicAlbumDetailView.swift"
        )

        XCTAssertTrue(detailView.contains("EntityDetailToolbarMenu("))
        XCTAssertTrue(detailView.contains("AddToCollectionSheet("))
        XCTAssertTrue(toolbarMenu.contains("Menu {"))
        XCTAssertTrue(toolbarMenu.contains("Label(\"Add to Collection\""))
        XCTAssertTrue(toolbarMenu.contains("entity-detail.add-to-collection"))
        XCTAssertTrue(toolbarMenu.contains("entity-detail.more-actions"))
        XCTAssertFalse(albumDetail.contains("collectionSheetPresented"))
    }

    func testDetailSectionsUseANativeSegmentedPicker() throws {
        let picker = try sourceFile(
            "PrismediaShared/Features/EntityDetail/Components/EntityDetailSectionPicker.swift"
        )

        XCTAssertTrue(picker.contains("Picker(\"Detail section\""))
        XCTAssertTrue(picker.contains(".pickerStyle(.segmented)"))
        XCTAssertFalse(picker.contains("Button {"))
        XCTAssertFalse(picker.contains("ScrollView("))
    }

    func testSelectedSectionControlsUncardedContentImmediatelyBelowThePicker() throws {
        let detailView = try sourceFile(
            "PrismediaShared/Features/EntityDetail/EntityDetailView.swift"
        )
        let sectionContent = try sourceFile(
            "PrismediaShared/Features/EntityDetail/Components/EntityDetailSectionContentView.swift"
        )
        let sectionPanel = try sourceFile(
            "PrismediaShared/Features/EntityDetail/Components/EntityDetailSectionPanel.swift"
        )

        XCTAssertTrue(detailView.contains("EntityDetailSectionContentView("))
        XCTAssertTrue(sectionContent.contains("EntityDetailSectionPicker("))
        XCTAssertTrue(sectionContent.contains("section: selection"))
        XCTAssertFalse(sectionPanel.contains(".prismediaPanel()"))
        XCTAssertFalse(sectionPanel.contains("elevatedContentBackground"))
        XCTAssertFalse(sectionPanel.contains("clipShape(.rect(cornerRadius:"))
    }

    func testProgressSurfaceOwnsResumeWithoutDuplicatingItInTheHero() throws {
        let detailView = try sourceFile(
            "PrismediaShared/Features/EntityDetail/EntityDetailView.swift"
        )

        XCTAssertTrue(detailView.contains("readingState.progressPresentation?.canResume == true"))
        XCTAssertTrue(detailView.contains("presentation.actionTitle != \"Continue Listening\""))
    }

    private func sourceFile(_ path: String) throws -> String {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: root.appending(path: path),
            encoding: .utf8
        )
    }
}
