import Foundation

public struct EPUBReaderPreferences: Codable, Equatable, Sendable {
    public var flow: ReaderMode
    public var theme: EPUBReaderTheme
    public var fontFamily: EPUBReaderFontFamily
    public var fontScale: Double
    public var lineHeight: Double
    public var pageMargins: Double

    public init(
        flow: ReaderMode = .paged,
        theme: EPUBReaderTheme = .system,
        fontFamily: EPUBReaderFontFamily = .publisher,
        fontScale: Double = 1,
        lineHeight: Double = 1.5,
        pageMargins: Double = 1
    ) {
        self.flow = flow == .scrolled ? .scrolled : .paged
        self.theme = theme
        self.fontFamily = fontFamily
        self.fontScale = min(max(fontScale, 0.8), 2)
        self.lineHeight = min(max(lineHeight, 1.2), 2)
        self.pageMargins = min(max(pageMargins, 0.5), 2)
    }

    public func replacing(
        flow: ReaderMode? = nil,
        theme: EPUBReaderTheme? = nil,
        fontFamily: EPUBReaderFontFamily? = nil,
        fontScale: Double? = nil,
        lineHeight: Double? = nil,
        pageMargins: Double? = nil
    ) -> Self {
        Self(
            flow: flow ?? self.flow,
            theme: theme ?? self.theme,
            fontFamily: fontFamily ?? self.fontFamily,
            fontScale: fontScale ?? self.fontScale,
            lineHeight: lineHeight ?? self.lineHeight,
            pageMargins: pageMargins ?? self.pageMargins
        )
    }
}
