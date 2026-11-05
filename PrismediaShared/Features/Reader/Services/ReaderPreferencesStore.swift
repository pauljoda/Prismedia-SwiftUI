import Foundation

public struct ReaderPreferencesStore: @unchecked Sendable {
    public static let epubDefaultsKey = "prismedia.reader.epub.preferences.v1"
    public static let pdfPageLayoutDefaultsKey = "prismedia.reader.pdf.page-layout.v1"
    public static let comicReadingDirectionsDefaultsKey = "prismedia.reader.comic.reading-directions.v1"

    private let defaults: UserDefaults?

    public static var standard: Self {
        Self(defaults: .standard)
    }

    public static var disabled: Self {
        Self(defaults: nil)
    }

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    private init(defaults: UserDefaults?) {
        self.defaults = defaults
    }

    public func loadEPUB() -> EPUBReaderPreferences {
        guard
            let data = defaults?.data(forKey: Self.epubDefaultsKey),
            let preferences = try? JSONDecoder().decode(EPUBReaderPreferences.self, from: data)
        else { return EPUBReaderPreferences() }
        return preferences
    }

    public func save(_ preferences: EPUBReaderPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults?.set(data, forKey: Self.epubDefaultsKey)
    }

    public func loadPDFPageLayout() -> PDFReaderPageLayout {
        guard let stored = defaults?.string(forKey: Self.pdfPageLayoutDefaultsKey) else { return .automatic }
        return PDFReaderPageLayout(rawValue: stored) ?? .automatic
    }

    public func save(_ pageLayout: PDFReaderPageLayout) {
        defaults?.set(pageLayout.rawValue, forKey: Self.pdfPageLayoutDefaultsKey)
    }

    /// The reading direction chosen for a comic series, or Automatic when none was chosen.
    public func loadComicReadingDirection(seriesID: UUID) -> ComicReadingDirection {
        guard let stored = comicReadingDirections()[seriesID.uuidString] else { return .automatic }
        return ComicReadingDirection(rawValue: stored) ?? .automatic
    }

    /// Keeps a reading direction for a comic series; Automatic forgets the series.
    public func save(_ direction: ComicReadingDirection, seriesID: UUID) {
        var directions = comicReadingDirections()
        directions[seriesID.uuidString] = direction == .automatic ? nil : direction.rawValue
        defaults?.set(directions, forKey: Self.comicReadingDirectionsDefaultsKey)
    }

    private func comicReadingDirections() -> [String: String] {
        defaults?.dictionary(forKey: Self.comicReadingDirectionsDefaultsKey) as? [String: String] ?? [:]
    }
}
