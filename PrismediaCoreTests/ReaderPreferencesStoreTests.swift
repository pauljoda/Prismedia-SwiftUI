import XCTest

@testable import PrismediaCore

final class ReaderPreferencesStoreTests: XCTestCase {
    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "ReaderPreferencesStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testComicReadingDirectionIsKeptPerSeriesAndAutomaticForgetsIt() {
        let store = ReaderPreferencesStore(defaults: defaults)
        let manga = UUID()
        let western = UUID()

        XCTAssertEqual(store.loadComicReadingDirection(seriesID: manga), .automatic)

        store.save(.rightToLeft, seriesID: manga)
        XCTAssertEqual(store.loadComicReadingDirection(seriesID: manga), .rightToLeft)
        XCTAssertEqual(store.loadComicReadingDirection(seriesID: western), .automatic)

        store.save(.automatic, seriesID: manga)
        XCTAssertEqual(store.loadComicReadingDirection(seriesID: manga), .automatic)
        XCTAssertNil(
            defaults.dictionary(forKey: ReaderPreferencesStore.comicReadingDirectionsDefaultsKey)?[manga.uuidString]
        )
    }

    func testPDFPageLayoutRoundTrips() {
        let store = ReaderPreferencesStore(defaults: defaults)

        XCTAssertEqual(store.loadPDFPageLayout(), .automatic)
        store.save(PDFReaderPageLayout.double)
        XCTAssertEqual(store.loadPDFPageLayout(), .double)
        XCTAssertEqual(ReaderPreferencesStore.disabled.loadPDFPageLayout(), .automatic)
    }
}
