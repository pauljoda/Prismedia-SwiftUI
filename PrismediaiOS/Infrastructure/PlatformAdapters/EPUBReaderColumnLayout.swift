#if os(iOS) && canImport(ReadiumNavigator)
    import Foundation
    @preconcurrency import ReadiumNavigator

    /// How many columns a paginated EPUB shows, set through Readium CSS's reading
    /// system properties. Readium CSS honours the reader's column setting only from
    /// 60em (960 px) up, so iPhone Duo's 951 pt open display and most iPads fall
    /// back to its own defaults; these properties apply at every width.
    ///
    /// Automatic reads like a book: up to two columns, each at least
    /// ``automaticColumnWidth`` wide, so a landscape display shows a left and a
    /// right page and a portrait one a single page. Each column keeps the page
    /// gutter on both sides, so the gap between two columns sits on the centre of
    /// the display, where iPhone Duo folds.
    enum EPUBReaderColumnLayout {
        /// Fits two columns on iPhone Duo's open display in landscape (951 pt) and
        /// one in portrait (669 pt) or on an iPad in portrait (820 pt), whatever
        /// the font size.
        static let automaticColumnWidth: Double = 420

        static func readingSystemProperties(for columnCount: EPUBReaderColumnCount) -> CSSRSProperties {
            switch columnCount {
            case .automatic:
                CSSRSProperties(colWidth: CSSPxLength(automaticColumnWidth), colCount: .two)
            case .one:
                CSSRSProperties(colCount: .one)
            case .two:
                CSSRSProperties(colWidth: CSSPxLength(1), colCount: .two)
            }
        }
    }
#endif
