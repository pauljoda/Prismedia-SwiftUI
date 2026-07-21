enum VideoPlaybackScanPolicy {
    static let rates: [Float] = [2, 4, 8, 16, 32]

    static func nextRate(
        currentSide: VideoPlayerGestureSide?,
        currentRate: Float,
        direction: VideoPlayerGestureSide
    ) -> Float {
        guard currentSide == direction,
            let currentIndex = rates.firstIndex(of: currentRate)
        else { return rates[0] }

        return rates[min(currentIndex + 1, rates.count - 1)]
    }
}
