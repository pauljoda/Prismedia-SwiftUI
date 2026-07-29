#if canImport(UIKit) && !os(tvOS)
    import SwiftUI
    import UIKit

    /// Owns the fullscreen player's presentation for the lifetime of the view that
    /// launched it, mirroring `MacVideoFullscreenWindowController`.
    ///
    /// The hosting controller deliberately lives here rather than inside a
    /// representable's coordinator. Presenting a full-screen modal detaches the
    /// launching hierarchy, so SwiftUI may tear down and re-create a representable
    /// that sits inside it. A coordinator that dismisses on `dismantle` reads that
    /// re-parenting as the viewer closing the player and tears playback down a
    /// frame after it opened.
    @MainActor
    final class VideoFullscreenPresentationController {
        private var hostingController: VideoFullscreenHostingController?
        private var hostedContentID: AnyHashable?
        private var onDismiss: (() -> Void)?
        private var presentationTask: Task<Void, Never>?
        private var isDismissing = false
        private var deliveredDismissal = false

        func presentOrUpdate(
            content: AnyView,
            contentID: AnyHashable?,
            from presenter: UIViewController,
            onDismiss: @escaping () -> Void
        ) {
            self.onDismiss = onDismiss

            if let hostingController {
                // The hosted tree observes playback state directly. Replacing its
                // root on every player tick dismantles the UIKit adapters inside
                // it, so only a genuinely new controller warrants a new root.
                guard hostedContentID != contentID else { return }
                hostedContentID = contentID
                hostingController.rootView = content
                return
            }

            schedulePresentation(content: content, contentID: contentID, from: presenter)
        }

        /// Dismisses in response to the viewer leaving the player, reporting the
        /// dismissal so playback can be torn down.
        func requestDismissal() {
            dismiss(animated: true, reportsDismissal: true, source: "binding")
        }

        /// Tears the presentation down because the launching view itself went away.
        func closeImmediately() {
            dismiss(animated: false, reportsDismissal: true, source: "launcher disappeared")
        }

        private func schedulePresentation(
            content: AnyView,
            contentID: AnyHashable?,
            from presenter: UIViewController
        ) {
            guard presentationTask == nil, !isDismissing else { return }
            presentationTask = Task { @MainActor [weak self, weak presenter] in
                // Never present from inside a SwiftUI update pass.
                await Task.yield()
                guard let self else { return }
                presentationTask = nil
                guard let presenter,
                    presenter.viewIfLoaded?.window != nil,
                    hostingController == nil,
                    !isDismissing
                else { return }

                deliveredDismissal = false
                let hostingController = VideoFullscreenHostingController(rootView: content)
                hostingController.modalPresentationStyle = .fullScreen
                hostingController.modalTransitionStyle = .coverVertical
                hostingController.modalPresentationCapturesStatusBarAppearance = true
                hostingController.onDismissed = { [weak self, weak hostingController] in
                    guard let self, let hostingController else { return }
                    finishDismissal(of: hostingController, source: "hosting controller")
                }
                self.hostingController = hostingController
                hostedContentID = contentID
                presenter.present(hostingController, animated: true)
            }
        }

        private func dismiss(animated: Bool, reportsDismissal: Bool, source: String) {
            presentationTask?.cancel()
            presentationTask = nil
            guard let hostingController, !isDismissing else { return }
            isDismissing = true
            if !reportsDismissal {
                deliveredDismissal = true
            }
            hostingController.dismiss(animated: animated) { [weak self, weak hostingController] in
                guard let self, let hostingController else { return }
                finishDismissal(of: hostingController, source: source)
            }
        }

        private func finishDismissal(
            of controller: VideoFullscreenHostingController,
            source: String
        ) {
            guard hostingController === controller else { return }
            hostingController = nil
            hostedContentID = nil
            isDismissing = false
            guard !deliveredDismissal else { return }
            deliveredDismissal = true
            #if DEBUG
                print("Video fullscreen dismissed by \(source).")
            #endif
            onDismiss?()
        }
    }
#endif
