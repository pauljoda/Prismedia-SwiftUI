#if canImport(UIKit) && !os(tvOS)
    import SwiftUI
    import UIKit

    @MainActor
    final class SceneCaptureView: UIView {
        var onWindowScene: ((UIWindowScene) -> Void)?
        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let scene = window?.windowScene else { return }
            onWindowScene?(scene)
        }
    }

    #if DEBUG
        #Preview("Scene Capture View") {
            let view = SceneCaptureView()
            view.backgroundColor = .systemBackground
            return view
        }
    #endif
#endif
