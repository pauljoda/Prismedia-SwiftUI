#if canImport(UIKit) && !os(tvOS)
    import SwiftUI
    import UIKit

    /// UIKit owns the orientation contract for the fullscreen player. SwiftUI's
    /// presentation host can otherwise retain the portrait-only contract of the
    /// page that launched it, which makes a forced landscape transition invalid.
    ///
    /// This controller must stay PERMISSIVE: landscape is forced by narrowing the
    /// app-delegate mask once the player is on screen, never by locking this mask
    /// to landscape. The app-delegate mask is portrait when presentation begins
    /// and again during dismissal, and a landscape-only controller at either
    /// moment leaves UIKit without a common orientation — which it resolves by
    /// dismissing the player or throwing `UIApplicationInvalidInterfaceOrientation`.
    @MainActor
    final class VideoFullscreenHostingController: UIHostingController<AnyView> {
        var onDismissed: (() -> Void)?

        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            UIDevice.current.userInterfaceIdiom == .pad ? .all : .allButUpsideDown
        }

        override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
            .landscapeRight
        }

        override var shouldAutorotate: Bool { true }

        override var prefersStatusBarHidden: Bool { true }

        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            guard isBeingDismissed || presentingViewController == nil else { return }
            onDismissed?()
        }
    }
#endif
