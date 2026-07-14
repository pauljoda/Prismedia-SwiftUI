import CoreGraphics

enum EntityImageViewerDismissPolicy {
    private static let minimumDismissDistance: CGFloat = 120
    private static let verticalDominance: CGFloat = 1.25

    static func shouldDismiss(
        translation: CGSize,
        predictedEndTranslation: CGSize
    ) -> Bool {
        qualifiesForDismissal(translation)
            || qualifiesForDismissal(predictedEndTranslation)
    }

    static func interactiveOffset(for translation: CGSize) -> CGFloat {
        guard isDominantDownwardMovement(translation) else { return 0 }
        return translation.height
    }

    private static func qualifiesForDismissal(_ translation: CGSize) -> Bool {
        translation.height >= minimumDismissDistance
            && isDominantDownwardMovement(translation)
    }

    private static func isDominantDownwardMovement(_ translation: CGSize) -> Bool {
        translation.height > 0
            && translation.height > abs(translation.width) * verticalDominance
    }
}
