import Foundation

struct MusicPlaybackRateOption: Identifiable, Sendable {
    let rate: Float

    var id: Float { rate }
    var label: String { rate.formatted(.number.precision(.fractionLength(rate == rate.rounded() ? 0 : 2))) + "×" }

    static let standard = [0.5, 0.75, 1, 1.25, 1.5, 1.75, 2].map(Self.init(rate:))
}
