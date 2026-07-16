import Foundation

public enum EPUBReadingProfile: String, CaseIterable, Codable, Hashable, Sendable {
    case paper
    case comfortable
    case focus
    case accessible
    case night
    case original
    case custom

    public static let selectableCases: [Self] = [
        .paper,
        .comfortable,
        .focus,
        .accessible,
        .night,
        .original,
    ]

    public var preferences: EPUBReaderPreferences {
        switch self {
        case .paper:
            EPUBReaderPreferences()
        case .comfortable:
            EPUBReaderPreferences(
                theme: .system,
                fontScale: 1.1,
                fontWeight: 1,
                lineHeight: 1.6,
                paragraphSpacing: 0.35,
                paragraphIndent: 0,
                pageMargins: 1.5,
                textAlignment: .leading,
                hyphenationEnabled: false
            )
        case .focus:
            EPUBReaderPreferences(
                flow: .scrolled,
                fontScale: 1.1,
                fontWeight: 1,
                lineHeight: 1.6,
                paragraphSpacing: 0.25,
                paragraphIndent: 0,
                pageMargins: 1.5,
                textAlignment: .leading,
                hyphenationEnabled: false,
                scrollFocusEnabled: true,
                scrollFocusStrength: 0.6
            )
        case .accessible:
            EPUBReaderPreferences(
                theme: .system,
                fontFamily: .accessible,
                fontScale: 1.2,
                fontWeight: 1.1,
                lineHeight: 1.7,
                letterSpacing: 0.05,
                wordSpacing: 0.1,
                paragraphSpacing: 0.4,
                paragraphIndent: 0,
                pageMargins: 1.4,
                textAlignment: .leading,
                hyphenationEnabled: false,
                textNormalizationEnabled: true
            )
        case .night:
            EPUBReaderPreferences(
                theme: .dark,
                fontScale: 1.05,
                fontWeight: 1.1,
                lineHeight: 1.55,
                paragraphSpacing: 0.2,
                paragraphIndent: 0,
                pageMargins: 1.4,
                textAlignment: .leading,
                hyphenationEnabled: false
            )
        case .original:
            EPUBReaderPreferences(
                theme: .system,
                fontFamily: .publisher,
                fontWeight: 1,
                lineHeight: 1.2,
                paragraphIndent: 0,
                pageMargins: 1,
                textAlignment: .automatic,
                hyphenationEnabled: false,
                usesPublisherStyles: true
            )
        case .custom:
            EPUBReaderPreferences()
        }
    }
}
