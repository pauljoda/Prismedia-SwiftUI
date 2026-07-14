import Foundation

enum TVEpisodePreviewFrameSampler {
    private static let previewRange = 0.2...0.7

    static func sample(
        _ frames: [TrickplayPlaylist.Frame],
        limit: Int
    ) -> [TrickplayPlaylist.Frame] {
        guard limit > 0, !frames.isEmpty else { return [] }

        let maximumIndex = frames.count - 1
        let firstIndex = Int((Double(maximumIndex) * previewRange.lowerBound).rounded())
        let lastIndex = Int((Double(maximumIndex) * previewRange.upperBound).rounded())
        let availableCount = lastIndex - firstIndex + 1
        let sampleCount = min(limit, availableCount)
        guard sampleCount > 1 else { return [frames[firstIndex]] }

        return (0..<sampleCount).map { index in
            let progress = Double(index) / Double(sampleCount - 1)
            let position = Double(firstIndex) + (Double(lastIndex - firstIndex) * progress)
            return frames[Int(position.rounded())]
        }
    }
}
