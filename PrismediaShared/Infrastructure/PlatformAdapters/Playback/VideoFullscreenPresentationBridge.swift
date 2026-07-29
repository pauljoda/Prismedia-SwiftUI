#if canImport(UIKit) && !os(tvOS)
    import SwiftUI
    import UIKit

    /// Forwards the fullscreen player's presentation state to a controller that
    /// outlives this representable. Presentation itself is deliberately not owned
    /// here: a full-screen modal detaches the hierarchy that launched it, and a
    /// representable in that hierarchy can be torn down and re-created as a result.
    /// Dismissing on `dismantle` would turn that re-parenting into an instant,
    /// spurious dismissal of the player.
    struct VideoFullscreenPresentationBridge<FullscreenContent: View>: UIViewControllerRepresentable {
        let isPresented: Bool
        let fullscreenContent: FullscreenContent
        let contentID: AnyHashable?
        let presentationController: VideoFullscreenPresentationController
        let onDismiss: () -> Void

        func makeUIViewController(context: Context) -> UIViewController {
            let controller = UIViewController()
            controller.view.backgroundColor = .clear
            controller.view.isUserInteractionEnabled = false
            return controller
        }

        func updateUIViewController(
            _ presenter: UIViewController,
            context: Context
        ) {
            if isPresented {
                presentationController.presentOrUpdate(
                    content: AnyView(fullscreenContent),
                    contentID: contentID,
                    from: presenter,
                    onDismiss: onDismiss
                )
            } else {
                presentationController.requestDismissal()
            }
        }
    }

    #if DEBUG
        #Preview("Video Fullscreen Presentation Bridge") {
            VideoFullscreenPresentationBridge(
                isPresented: false,
                fullscreenContent: Color.black,
                contentID: nil,
                presentationController: VideoFullscreenPresentationController(),
                onDismiss: {}
            )
            .frame(width: 1, height: 1)
        }
    #endif
#endif
