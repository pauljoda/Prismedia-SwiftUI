import SwiftUI

#if canImport(UIKit) && !os(tvOS)
    import UIKit

    struct VideoFullscreenOrientationRequest: UIViewRepresentable {
        @Binding var usesRotatedFallback: Bool
        let controller: VideoFullscreenOrientationController
        private let requestsFullscreen: Bool

        init(
            usesRotatedFallback: Binding<Bool>,
            controller: VideoFullscreenOrientationController
        ) {
            _usesRotatedFallback = usesRotatedFallback
            self.controller = controller
            requestsFullscreen = true
        }

        #if DEBUG
            init(
                previewUsesRotatedFallback: Binding<Bool>,
                controller: VideoFullscreenOrientationController
            ) {
                _usesRotatedFallback = previewUsesRotatedFallback
                self.controller = controller
                requestsFullscreen = false
            }
        #endif

        func makeUIView(context: Context) -> SceneCaptureView {
            let view = SceneCaptureView()
            let fallback = $usesRotatedFallback
            controller.onFallbackChanged = { fallback.wrappedValue = $0 }
            view.onDismantle = { controller.sceneCaptureDidDismantle() }
            if requestsFullscreen {
                view.onWindowScene = { scene in controller.enterFullscreen(in: scene) }
            }
            return view
        }

        func updateUIView(_ view: SceneCaptureView, context: Context) {}

        static func dismantleUIView(
            _ view: SceneCaptureView,
            coordinator: Void
        ) {
            view.onDismantle?()
            view.onWindowScene = nil
            view.onDismantle = nil
        }
    }

#else
    struct VideoFullscreenOrientationRequest: View {
        @Binding var usesRotatedFallback: Bool
        let controller: VideoFullscreenOrientationController

        init(
            usesRotatedFallback: Binding<Bool>,
            controller: VideoFullscreenOrientationController
        ) {
            _usesRotatedFallback = usesRotatedFallback
            self.controller = controller
        }

        #if DEBUG
            init(
                previewUsesRotatedFallback: Binding<Bool>,
                controller: VideoFullscreenOrientationController
            ) {
                _usesRotatedFallback = previewUsesRotatedFallback
                self.controller = controller
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
                    previewUsesRotatedFallback: .constant(false),
                    controller: VideoFullscreenOrientationController()
                )
            )
    }
#endif
