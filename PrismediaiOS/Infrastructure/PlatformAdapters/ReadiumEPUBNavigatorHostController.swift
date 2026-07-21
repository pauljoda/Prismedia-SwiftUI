#if os(iOS) && canImport(ReadiumNavigator)
    import SwiftUI
    import UIKit

    @MainActor
    final class ReadiumEPUBNavigatorHostController: UIViewController {
        var isSwipeDownEnabled = false
        var onSwipeDown: (() -> Void)?

        private weak var installedController: UIViewController?
        private lazy var swipeDownGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handleSwipeDown)
        )

        init() {
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            swipeDownGesture.cancelsTouchesInView = false
            swipeDownGesture.maximumNumberOfTouches = 1
            swipeDownGesture.delegate = self
            view.addGestureRecognizer(swipeDownGesture)
        }

        func install(_ controller: UIViewController) {
            guard installedController !== controller else { return }
            if let installedController {
                installedController.willMove(toParent: nil)
                installedController.view.removeFromSuperview()
                installedController.removeFromParent()
            }

            addChild(controller)
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(controller.view)
            NSLayoutConstraint.activate([
                controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                controller.view.topAnchor.constraint(equalTo: view.topAnchor),
                controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
            controller.didMove(toParent: self)
            installedController = controller
        }

        @objc private func handleSwipeDown(_ gesture: UIPanGestureRecognizer) {
            guard isSwipeDownEnabled, gesture.state == .ended else { return }
            let translation = gesture.translation(in: view)
            guard
                ReaderDismissGesture.shouldDismiss(
                    deltaX: translation.x,
                    deltaY: translation.y
                )
            else { return }
            onSwipeDown?()
        }
    }

    extension ReadiumEPUBNavigatorHostController: UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard gestureRecognizer === swipeDownGesture else { return true }
            guard isSwipeDownEnabled,
                let panGesture = gestureRecognizer as? UIPanGestureRecognizer
            else { return false }

            let velocity = panGesture.velocity(in: view)
            return velocity.y > 0 && abs(velocity.y) > abs(velocity.x) * 1.3
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            gestureRecognizer === swipeDownGesture || otherGestureRecognizer === swipeDownGesture
        }
    }

    #if DEBUG
        #Preview("Readium EPUB Host Controller") {
            let controller = ReadiumEPUBNavigatorHostController()
            controller.view.backgroundColor = .systemBackground
            return controller
        }
    #endif
#endif
