struct VideoSubtitleTextStyle: OptionSet, Equatable, Sendable {
    let rawValue: UInt8

    static let bold = Self(rawValue: 1 << 0)
    static let italic = Self(rawValue: 1 << 1)
    static let underline = Self(rawValue: 1 << 2)
}
