import Foundation

public struct EPUBReaderPreferences: Codable, Equatable, Sendable {
    public var flow: ReaderMode
    public var theme: EPUBReaderTheme
    public var fontFamily: EPUBReaderFontFamily
    public var fontScale: Double
    public var fontWeight: Double
    public var lineHeight: Double
    public var letterSpacing: Double
    public var wordSpacing: Double
    public var paragraphSpacing: Double
    public var paragraphIndent: Double
    public var pageMargins: Double
    public var textAlignment: EPUBReaderTextAlignment
    public var columnCount: EPUBReaderColumnCount
    public var hyphenationEnabled: Bool
    public var textNormalizationEnabled: Bool
    public var usesPublisherStyles: Bool
    public var scrollFocusEnabled: Bool
    public var scrollFocusStrength: Double
    public var readingGuideEnabled: Bool

    public init(
        flow: ReaderMode = .paged,
        theme: EPUBReaderTheme = .paper,
        fontFamily: EPUBReaderFontFamily = .serif,
        fontScale: Double = 1,
        fontWeight: Double = 1.05,
        lineHeight: Double = 1.5,
        letterSpacing: Double = 0,
        wordSpacing: Double = 0,
        paragraphSpacing: Double = 0,
        paragraphIndent: Double = 0.8,
        pageMargins: Double = 1.3,
        textAlignment: EPUBReaderTextAlignment = .justified,
        columnCount: EPUBReaderColumnCount = .automatic,
        hyphenationEnabled: Bool = true,
        textNormalizationEnabled: Bool = false,
        usesPublisherStyles: Bool = false,
        scrollFocusEnabled: Bool = false,
        scrollFocusStrength: Double = 0.6,
        readingGuideEnabled: Bool = false
    ) {
        self.flow = flow == .scrolled ? .scrolled : .paged
        self.theme = theme
        self.fontFamily = fontFamily
        self.fontScale = fontScale.clamped(to: 0.8...2)
        self.fontWeight = fontWeight.clamped(to: 0.75...1.5)
        self.lineHeight = lineHeight.clamped(to: 1.2...2)
        self.letterSpacing = letterSpacing.clamped(to: 0...0.3)
        self.wordSpacing = wordSpacing.clamped(to: 0...0.5)
        self.paragraphSpacing = paragraphSpacing.clamped(to: 0...1.5)
        self.paragraphIndent = paragraphIndent.clamped(to: 0...2)
        self.pageMargins = pageMargins.clamped(to: 0.5...2.5)
        self.textAlignment = textAlignment
        self.columnCount = columnCount
        self.hyphenationEnabled = hyphenationEnabled
        self.textNormalizationEnabled = textNormalizationEnabled
        self.usesPublisherStyles = usesPublisherStyles
        self.scrollFocusEnabled = scrollFocusEnabled
        self.scrollFocusStrength = scrollFocusStrength.clamped(to: 0.25...0.8)
        self.readingGuideEnabled = readingGuideEnabled
    }

    public var matchingProfile: EPUBReadingProfile {
        EPUBReadingProfile.selectableCases.first { $0.preferences == self } ?? .custom
    }

    public func replacing(
        flow: ReaderMode? = nil,
        theme: EPUBReaderTheme? = nil,
        fontFamily: EPUBReaderFontFamily? = nil,
        fontScale: Double? = nil,
        fontWeight: Double? = nil,
        lineHeight: Double? = nil,
        letterSpacing: Double? = nil,
        wordSpacing: Double? = nil,
        paragraphSpacing: Double? = nil,
        paragraphIndent: Double? = nil,
        pageMargins: Double? = nil,
        textAlignment: EPUBReaderTextAlignment? = nil,
        columnCount: EPUBReaderColumnCount? = nil,
        hyphenationEnabled: Bool? = nil,
        textNormalizationEnabled: Bool? = nil,
        usesPublisherStyles: Bool? = nil,
        scrollFocusEnabled: Bool? = nil,
        scrollFocusStrength: Double? = nil,
        readingGuideEnabled: Bool? = nil
    ) -> Self {
        Self(
            flow: flow ?? self.flow,
            theme: theme ?? self.theme,
            fontFamily: fontFamily ?? self.fontFamily,
            fontScale: fontScale ?? self.fontScale,
            fontWeight: fontWeight ?? self.fontWeight,
            lineHeight: lineHeight ?? self.lineHeight,
            letterSpacing: letterSpacing ?? self.letterSpacing,
            wordSpacing: wordSpacing ?? self.wordSpacing,
            paragraphSpacing: paragraphSpacing ?? self.paragraphSpacing,
            paragraphIndent: paragraphIndent ?? self.paragraphIndent,
            pageMargins: pageMargins ?? self.pageMargins,
            textAlignment: textAlignment ?? self.textAlignment,
            columnCount: columnCount ?? self.columnCount,
            hyphenationEnabled: hyphenationEnabled ?? self.hyphenationEnabled,
            textNormalizationEnabled: textNormalizationEnabled ?? self.textNormalizationEnabled,
            usesPublisherStyles: usesPublisherStyles ?? self.usesPublisherStyles,
            scrollFocusEnabled: scrollFocusEnabled ?? self.scrollFocusEnabled,
            scrollFocusStrength: scrollFocusStrength ?? self.scrollFocusStrength,
            readingGuideEnabled: readingGuideEnabled ?? self.readingGuideEnabled
        )
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Self()
        let fontFamily =
            try values.decodeIfPresent(EPUBReaderFontFamily.self, forKey: .fontFamily)
            ?? defaults.fontFamily
        self.init(
            flow: try values.decodeIfPresent(ReaderMode.self, forKey: .flow) ?? defaults.flow,
            theme: try values.decodeIfPresent(EPUBReaderTheme.self, forKey: .theme) ?? defaults.theme,
            fontFamily: fontFamily,
            fontScale: try values.decodeIfPresent(Double.self, forKey: .fontScale) ?? defaults.fontScale,
            fontWeight: try values.decodeIfPresent(Double.self, forKey: .fontWeight) ?? defaults.fontWeight,
            lineHeight: try values.decodeIfPresent(Double.self, forKey: .lineHeight) ?? defaults.lineHeight,
            letterSpacing: try values.decodeIfPresent(Double.self, forKey: .letterSpacing)
                ?? defaults.letterSpacing,
            wordSpacing: try values.decodeIfPresent(Double.self, forKey: .wordSpacing)
                ?? defaults.wordSpacing,
            paragraphSpacing: try values.decodeIfPresent(Double.self, forKey: .paragraphSpacing)
                ?? defaults.paragraphSpacing,
            paragraphIndent: try values.decodeIfPresent(Double.self, forKey: .paragraphIndent)
                ?? defaults.paragraphIndent,
            pageMargins: try values.decodeIfPresent(Double.self, forKey: .pageMargins)
                ?? defaults.pageMargins,
            textAlignment: try values.decodeIfPresent(EPUBReaderTextAlignment.self, forKey: .textAlignment)
                ?? .automatic,
            columnCount: try values.decodeIfPresent(EPUBReaderColumnCount.self, forKey: .columnCount)
                ?? defaults.columnCount,
            hyphenationEnabled: try values.decodeIfPresent(Bool.self, forKey: .hyphenationEnabled)
                ?? defaults.hyphenationEnabled,
            textNormalizationEnabled: try values.decodeIfPresent(Bool.self, forKey: .textNormalizationEnabled)
                ?? defaults.textNormalizationEnabled,
            usesPublisherStyles: try values.decodeIfPresent(Bool.self, forKey: .usesPublisherStyles)
                ?? (fontFamily == .publisher),
            scrollFocusEnabled: try values.decodeIfPresent(Bool.self, forKey: .scrollFocusEnabled)
                ?? false,
            scrollFocusStrength: try values.decodeIfPresent(Double.self, forKey: .scrollFocusStrength)
                ?? defaults.scrollFocusStrength,
            readingGuideEnabled: try values.decodeIfPresent(Bool.self, forKey: .readingGuideEnabled)
                ?? false
        )
    }

    private enum CodingKeys: String, CodingKey {
        case flow
        case theme
        case fontFamily
        case fontScale
        case fontWeight
        case lineHeight
        case letterSpacing
        case wordSpacing
        case paragraphSpacing
        case paragraphIndent
        case pageMargins
        case textAlignment
        case columnCount
        case hyphenationEnabled
        case textNormalizationEnabled
        case usesPublisherStyles
        case scrollFocusEnabled
        case scrollFocusStrength
        case readingGuideEnabled
    }
}

extension Double {
    fileprivate func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
