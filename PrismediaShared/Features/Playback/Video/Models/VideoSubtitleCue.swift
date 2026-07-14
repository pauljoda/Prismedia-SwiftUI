struct VideoSubtitleCue: Equatable, Sendable {
    let startTime: Double
    let endTime: Double
    let content: VideoSubtitleText

    var text: String { content.plainText }
}
