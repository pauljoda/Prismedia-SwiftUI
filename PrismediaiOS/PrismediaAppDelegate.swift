import UIKit

@MainActor
final class PrismediaAppDelegate: NSObject, UIApplicationDelegate {
    static var supportedInterfaceOrientations: UIInterfaceOrientationMask = .portrait

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .all
        }
        return Self.supportedInterfaceOrientations
    }
}
