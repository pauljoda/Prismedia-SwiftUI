import Foundation

public struct VideoSubtitleAppearance: Equatable, Sendable {
    public static let `default` = VideoSubtitleAppearance(
        style: .stylized,
        fontScale: 1,
        positionPercent: 88,
        opacity: 1
    )

    public let style: VideoSubtitleDisplayStyle
    public let fontScale: Double
    public let positionPercent: Double
    public let opacity: Double

    var bottomInsetFraction: Double { 1 - positionPercent / 100 }

    public init(
        style: VideoSubtitleDisplayStyle,
        fontScale: Double,
        positionPercent: Double,
        opacity: Double
    ) {
        self.style = style
        self.fontScale = min(max(fontScale, 0.5), 3)
        self.positionPercent = min(max(positionPercent, 0), 100)
        self.opacity = min(max(opacity, 0.2), 1)
    }
}
