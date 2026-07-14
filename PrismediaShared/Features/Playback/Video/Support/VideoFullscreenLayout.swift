import CoreGraphics

enum VideoFullscreenLayout {
    static func shouldRotateFallback(enabled: Bool, width: CGFloat, height: CGFloat) -> Bool {
        enabled && height > width
    }
}
