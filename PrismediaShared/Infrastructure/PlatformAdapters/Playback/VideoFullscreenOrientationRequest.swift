import SwiftUI

#if canImport(UIKit) && !os(tvOS)
    import UIKit

    struct VideoFullscreenOrientationRequest: UIViewRepresentable {
        @Binding var usesRotatedFallback: Bool
        private let requestsFullscreen: Bool

        init(usesRotatedFallback: Binding<Bool>) {
            _usesRotatedFallback = usesRotatedFallback
            requestsFullscreen = true
        }

        #if DEBUG
            init(previewUsesRotatedFallback: Binding<Bool>) {
                _usesRotatedFallback = previewUsesRotatedFallback
                requestsFullscreen = false
            }
        #endif

        func makeCoordinator() -> Coordinator { Coordinator() }

        func makeUIView(context: Context) -> SceneCaptureView {
            let view = SceneCaptureView()
            let fallback = $usesRotatedFallback
            context.coordinator.onFallbackChanged = { fallback.wrappedValue = $0 }
            if requestsFullscreen {
                view.onWindowScene = { scene in context.coordinator.enterFullscreen(in: scene) }
            }
            return view
        }

        func updateUIView(_ view: SceneCaptureView, context: Context) {}

        static func dismantleUIView(_ view: SceneCaptureView, coordinator: Coordinator) {
            coordinator.exitFullscreen()
        }

        @MainActor
        final class Coordinator {
            private weak var windowScene: UIWindowScene?
            private var previousOrientation: UIInterfaceOrientationMask?
            var onFallbackChanged: ((Bool) -> Void)?

            func enterFullscreen(in scene: UIWindowScene) {
                guard windowScene == nil else { return }
                windowScene = scene
                previousOrientation = Self.mask(for: scene.effectiveGeometry.interfaceOrientation)
                guard
                    VideoFullscreenOrientationPolicy.forcesLandscape(
                        isPad: UIDevice.current.userInterfaceIdiom == .pad
                    )
                else {
                    onFallbackChanged?(false)
                    return
                }
                PrismediaAppDelegate.supportedInterfaceOrientations = .landscape
                Self.invalidateSupportedOrientations(in: scene)
                Task { @MainActor [weak self, weak scene] in
                    await Task.yield()
                    guard let self, let scene, self.windowScene === scene else { return }
                    scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape)) { error in
                        self.onFallbackChanged?(true)
                        #if DEBUG
                            print("Landscape fullscreen request was denied: \(error)")
                        #endif
                    }
                }
                Task { @MainActor [weak self, weak scene] in
                    try? await Task.sleep(for: .milliseconds(350))
                    guard let self, let scene, self.windowScene === scene else { return }
                    self.onFallbackChanged?(!scene.effectiveGeometry.interfaceOrientation.isLandscape)
                }
            }

            func exitFullscreen() {
                guard let windowScene, let previousOrientation else { return }
                if VideoFullscreenOrientationPolicy.forcesLandscape(
                    isPad: UIDevice.current.userInterfaceIdiom == .pad
                ) {
                    PrismediaAppDelegate.supportedInterfaceOrientations = previousOrientation
                    Self.invalidateSupportedOrientations(in: windowScene)
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: previousOrientation)) { error in
                        #if DEBUG
                            print("Player orientation restore was denied: \(error)")
                        #endif
                    }
                }
                self.windowScene = nil
                self.previousOrientation = nil
                onFallbackChanged?(false)
            }

            private static func mask(for orientation: UIInterfaceOrientation) -> UIInterfaceOrientationMask {
                switch orientation {
                case .portrait: .portrait
                case .portraitUpsideDown: .portraitUpsideDown
                case .landscapeLeft: .landscapeLeft
                case .landscapeRight: .landscapeRight
                case .unknown: .portrait
                @unknown default: .portrait
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
    }

#else
    struct VideoFullscreenOrientationRequest: View {
        @Binding var usesRotatedFallback: Bool

        init(usesRotatedFallback: Binding<Bool>) {
            _usesRotatedFallback = usesRotatedFallback
        }

        #if DEBUG
            init(previewUsesRotatedFallback: Binding<Bool>) {
                _usesRotatedFallback = previewUsesRotatedFallback
            }
        #endif

        var body: some View { EmptyView() }
    }
#endif

#if DEBUG
    #Preview("Fullscreen Orientation Probe") {
        Color.black
            .background(
                VideoFullscreenOrientationRequest(
                    previewUsesRotatedFallback: .constant(false)
                )
            )
    }
#endif
