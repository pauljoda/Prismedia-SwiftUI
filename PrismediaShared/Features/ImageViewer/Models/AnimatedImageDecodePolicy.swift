import Foundation

struct AnimatedImageDecodePolicy: Sendable {
    static func maximumPixelSize(
        requestedMaximumPixelSize: Int,
        frameCount: Int,
        decodedByteBudget: Int = 96 * 1_024 * 1_024
    ) -> Int {
        guard requestedMaximumPixelSize > 0, frameCount > 0, decodedByteBudget > 0 else {
            return max(1, requestedMaximumPixelSize)
        }
        let bytesPerFrame = max(1, decodedByteBudget / frameCount)
        let budgetedDimension = Int((Double(bytesPerFrame) / 4).squareRoot())
        return min(requestedMaximumPixelSize, max(1, budgetedDimension))
    }
}
