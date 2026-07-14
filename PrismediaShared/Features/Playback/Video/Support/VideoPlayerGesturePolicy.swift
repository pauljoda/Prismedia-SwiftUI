import CoreGraphics

enum VideoPlayerGesturePolicy {
    static func side(at x: CGFloat, width: CGFloat) -> VideoPlayerGestureSide { x < width / 2 ? .left : .right }
    static func shouldDismissFullscreen(translation: CGSize) -> Bool {
        translation.height > 72 && abs(translation.width) < translation.height * 0.75
    }
}
