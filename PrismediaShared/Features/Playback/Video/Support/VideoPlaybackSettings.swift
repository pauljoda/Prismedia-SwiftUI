import Foundation

enum VideoPlaybackSettings {
    static let availableRates: [Float] = [0.5, 0.75, 1, 1.25, 1.5, 2]
    static func label(for rate: Float) -> String {
        rate == 1 ? "Normal" : "\(rate.formatted(.number.precision(.fractionLength(0 ... 2))))×"
    }
}
