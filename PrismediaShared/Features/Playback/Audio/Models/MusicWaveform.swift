import Foundation

public struct MusicWaveform: Decodable, Equatable, Sendable {
    public static let maximumDisplayPairCount = 4_096

    public let samples: [Double]

    public init(samples: [Double]) {
        self.samples = Self.displaySamples(from: samples)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(samples: try container.decode([Double].self, forKey: .data))
    }

    public var pairCount: Int { samples.count / 2 }

    public var maximumAmplitude: Double {
        max(samples.lazy.map(abs).max() ?? 0, 1)
    }

    private enum CodingKeys: String, CodingKey {
        case data
    }

    private static func displaySamples(from samples: [Double]) -> [Double] {
        let pairCount = samples.count / 2
        guard pairCount > 0 else { return [] }
        let pairedSamples = Array(samples.prefix(pairCount * 2))
        guard pairCount > maximumDisplayPairCount else { return pairedSamples }

        var display = Array(repeating: 0.0, count: maximumDisplayPairCount * 2)
        for target in 0..<maximumDisplayPairCount {
            let sourceStart = target * pairCount / maximumDisplayPairCount
            let sourceEnd = max(
                sourceStart + 1,
                (target + 1) * pairCount / maximumDisplayPairCount
            )
            var bucketMinimum = 0.0
            var bucketMaximum = 0.0

            for source in sourceStart..<sourceEnd {
                let minimum = pairedSamples[source * 2]
                let maximum = pairedSamples[(source * 2) + 1]
                if minimum.isFinite { bucketMinimum = min(bucketMinimum, minimum) }
                if maximum.isFinite { bucketMaximum = max(bucketMaximum, maximum) }
            }

            display[target * 2] = bucketMinimum
            display[(target * 2) + 1] = bucketMaximum
        }
        return display
    }
}
