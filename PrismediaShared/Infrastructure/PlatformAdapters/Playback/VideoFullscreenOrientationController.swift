#if canImport(UIKit) && !os(tvOS)
    import UIKit

    @MainActor
    final class VideoFullscreenOrientationController {
        private weak var windowScene: UIWindowScene?
        private var restorationOrientations: UIInterfaceOrientationMask?
        private var isFullscreenActive = false
        private var isDismissalPending = false
        var onFallbackChanged: ((Bool) -> Void)?

        func prepareForPresentation() {
            isDismissalPending = false
        }

        func beginDismissal() {
            isDismissalPending = true
            isFullscreenActive = false
        }

        func sceneCaptureDidDismantle() {
            guard !isDismissalPending else { return }
            exitFullscreen()
        }

        func enterFullscreen(in scene: UIWindowScene) {
            guard !isFullscreenActive, !isDismissalPending else { return }
            guard
                VideoFullscreenOrientationPolicy.forcesLandscape(
                    isPad: UIDevice.current.userInterfaceIdiom == .pad
                )
            else {
                onFallbackChanged?(false)
                return
            }

            windowScene = scene
            restorationOrientations = PrismediaAppDelegate.supportedInterfaceOrientations
            isFullscreenActive = true
            PrismediaAppDelegate.supportedInterfaceOrientations = .landscape
            Self.invalidateSupportedOrientations(in: scene)
            requestLandscape(in: scene)
            verifyLandscape(in: scene)
        }

        func exitFullscreen() {
            guard let windowScene, let restorationOrientations else {
                onFallbackChanged?(false)
                return
            }

            isFullscreenActive = false
            PrismediaAppDelegate.supportedInterfaceOrientations = restorationOrientations
            Self.invalidateSupportedOrientations(in: windowScene)
            windowScene.requestGeometryUpdate(
                .iOS(interfaceOrientations: restorationOrientations)
            ) { error in
                #if DEBUG
                    print("Player orientation restore was denied: \(error)")
                #endif
            }
            onFallbackChanged?(false)
        }

        private func requestLandscape(in scene: UIWindowScene) {
            Task { @MainActor [weak self, weak scene] in
                await Task.yield()
                guard let self, let scene, self.isFullscreenActive, self.windowScene === scene else {
                    return
                }
                scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape)) { [weak self, weak scene] error in
                    guard let self, let scene, self.isFullscreenActive, self.windowScene === scene else {
                        return
                    }
                    self.onFallbackChanged?(true)
                    #if DEBUG
                        print("Landscape fullscreen request was denied: \(error)")
                    #endif
                }
            }
        }

        private func verifyLandscape(in scene: UIWindowScene) {
            Task { @MainActor [weak self, weak scene] in
                try? await Task.sleep(for: .milliseconds(350))
                guard let self, let scene, self.isFullscreenActive, self.windowScene === scene else {
                    return
                }
                self.onFallbackChanged?(!scene.effectiveGeometry.interfaceOrientation.isLandscape)
            }
        }

        private static func invalidateSupportedOrientations(in scene: UIWindowScene) {
            for window in scene.windows {
                var controller = window.rootViewController
                while let presented = controller?.presentedViewController {
                    controller = presented
                }
                controller?.setNeedsUpdateOfSupportedInterfaceOrientations()
                controller?.setNeedsUpdateOfPrefersInterfaceOrientationLocked()
            }
        }

    }
#else
    @MainActor
    final class VideoFullscreenOrientationController {
        func prepareForPresentation() {}
        func beginDismissal() {}
        func sceneCaptureDidDismantle() {}
        func exitFullscreen() {}
    }
#endif
