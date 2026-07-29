import UIKit

/// Routes every view controller's orientation contract through the single
/// app-level mask (`PrismediaAppDelegate.supportedInterfaceOrientations`).
///
/// Without this, SwiftUI's private presentation hosting controllers report the
/// portrait contract of the page that launched them. When fullscreen video
/// narrows the app mask to landscape, UIKit is left with no common orientation
/// between the application and the presented controller and resolves the
/// conflict by dismissing the player (or throwing
/// `UIApplicationInvalidInterfaceOrientation`). With one shared source of truth
/// no controller can ever disagree. Same approach Swiftfin uses in production.
extension UIViewController {
    static let installPrismediaOrientationResolution: Void = {
        guard
            let original = class_getInstanceMethod(
                UIViewController.self,
                #selector(getter: supportedInterfaceOrientations)
            ),
            let replacement = class_getInstanceMethod(
                UIViewController.self,
                #selector(prismediaSupportedInterfaceOrientations)
            )
        else { return }
        method_exchangeImplementations(original, replacement)
    }()

    @objc
    private func prismediaSupportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .all
        }
        return PrismediaAppDelegate.supportedInterfaceOrientations
    }
}
