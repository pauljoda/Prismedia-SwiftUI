import CoreGraphics
import Foundation

enum VideoFilmstripLayout {
    static func projectedTime(
        from startTime: Double, predictedTranslation: CGFloat, trackWidth: CGFloat, duration: Double
    ) -> Double {
        guard trackWidth > 0, duration > 0 else { return max(0, startTime) }
        return max(0, min(duration, startTime - Double(predictedTranslation / trackWidth) * duration))
    }
    static func continuousIndex(at time: Double, frames: [TrickplayPlaylist.Frame], duration: Double? = nil) -> Double {
        guard !frames.isEmpty else { return 0 }
        guard let lowerIndex = lowerFrameIndex(at: time, frames: frames, startTime: \.startTime) else { return 0 }
        if lowerIndex == frames.count - 1 {
            let lower = frames[lowerIndex].startTime
            let estimatedSpan = lowerIndex > 0 ? lower - frames[lowerIndex - 1].startTime : 1
            let upper = max(lower + estimatedSpan, duration ?? 0)
            guard upper > lower else { return Double(lowerIndex) }
            return Double(lowerIndex) + max(0, min(1, (time - lower) / (upper - lower)))
        }
        let lower = frames[lowerIndex].startTime
        let upper = frames[lowerIndex + 1].startTime
        guard upper > lower else { return Double(lowerIndex) }
        return Double(lowerIndex) + max(0, min(1, (time - lower) / (upper - lower)))
    }
    static func lowerFrameIndex<Frame>(
        at time: Double,
        frames: [Frame],
        startTime: (Frame) -> Double
    ) -> Int? {
        var lowerBound = 0
        var upperBound = frames.count

        while lowerBound < upperBound {
            let index = lowerBound + (upperBound - lowerBound) / 2
            if startTime(frames[index]) <= time {
                lowerBound = index + 1
            } else {
                upperBound = index
            }
        }

        return lowerBound == 0 ? nil : lowerBound - 1
    }
    static func visibleIndexes(at index: Double, frameCount: Int, radius: Int) -> [Int] {
        guard frameCount > 0 else { return [] }
        return Array(
            max(0, Int(index.rounded(.down)) - radius)...min(frameCount - 1, Int(index.rounded(.down)) + radius))
    }
    static func spriteURLsToPrewarm(at index: Double, frames: [TrickplayPlaylist.Frame], radius: Int) -> [URL] {
        var seen = Set<URL>()
        return visibleIndexes(at: index, frameCount: frames.count, radius: radius).map { frames[$0].imageURL }.filter {
            seen.insert($0).inserted
        }
    }
}
