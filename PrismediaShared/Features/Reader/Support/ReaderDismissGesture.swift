import CoreGraphics

public enum ReaderDismissGesture {
    public static func shouldDismiss(deltaX: CGFloat, deltaY: CGFloat) -> Bool {
        let horizontalDistance = abs(deltaX)
        let verticalDistance = abs(deltaY)

        return verticalDistance > 50
            && verticalDistance > horizontalDistance * 1.3
            && deltaY > 0
    }
}
