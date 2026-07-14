struct VideoSubtitleText: Equatable, Sendable {
    let runs: [VideoSubtitleTextRun]

    init(runs: [VideoSubtitleTextRun]) {
        self.runs = runs
    }

    init(_ text: String) {
        runs = [.init(text: text, style: [])]
    }

    var plainText: String {
        runs.map(\.text).joined()
    }
}
