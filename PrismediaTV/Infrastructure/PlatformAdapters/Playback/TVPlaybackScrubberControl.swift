#if os(tvOS)
    import SwiftUI
    import UIKit

    final class TVPlaybackScrubberControl: UIControl {
        var controlsVisible = true
        var isGrabbed = false
        var isScrollingEnabled = false {
            didSet { panGestureRecognizer.isEnabled = isScrollingEnabled }
        }

        var onFocusChange: (Bool) -> Void = { _ in }
        var onRevealControls: () -> Void = {}
        var onMoveToOptions: () -> Void = {}
        var onPrimaryAction: () -> Void = {}
        var onHorizontalPress: (VideoPlayerGestureSide) -> Void = { _ in }
        var onPanBegan: () -> Void = {}
        var onPanChanged: (CGFloat) -> Void = { _ in }
        var onPanEnded: () -> Void = {}

        private lazy var panGestureRecognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePan(_:))
        )
        private let contentHostingController: UIHostingController<AnyView>

        override var canBecomeFocused: Bool {
            isEnabled && !isHidden && alpha > 0
        }

        init(content: AnyView) {
            contentHostingController = UIHostingController(rootView: content)
            super.init(frame: .zero)
            backgroundColor = .clear
            isUserInteractionEnabled = true
            contentHostingController.view.backgroundColor = .clear
            contentHostingController.view.isUserInteractionEnabled = false
            contentHostingController.view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(contentHostingController.view)
            NSLayoutConstraint.activate([
                contentHostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
                contentHostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
                contentHostingController.view.topAnchor.constraint(equalTo: topAnchor),
                contentHostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
            panGestureRecognizer.isEnabled = false
            panGestureRecognizer.cancelsTouchesInView = false
            addGestureRecognizer(panGestureRecognizer)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setContent(_ content: AnyView) {
            contentHostingController.rootView = content
        }

        override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            let handled = presses.filter { press in
                switch press.type {
                case .leftArrow, .rightArrow, .select:
                    return true
                case .upArrow:
                    if !controlsVisible {
                        controlsVisible = true
                        onRevealControls()
                    } else if !isGrabbed {
                        onMoveToOptions()
                    }
                    return true
                case .downArrow:
                    if isGrabbed || !controlsVisible {
                        if !controlsVisible {
                            controlsVisible = true
                            onRevealControls()
                        }
                        return true
                    }
                    return false
                default:
                    return false
                }
            }
            let forwarded = presses.subtracting(handled)
            if !forwarded.isEmpty {
                super.pressesBegan(forwarded, with: event)
            }
        }

        override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            var forwarded = Set<UIPress>()
            for press in presses {
                switch press.type {
                case .leftArrow:
                    onHorizontalPress(.left)
                case .rightArrow:
                    onHorizontalPress(.right)
                case .select:
                    onPrimaryAction()
                case .upArrow,
                    .downArrow where isGrabbed || !controlsVisible:
                    break
                default:
                    forwarded.insert(press)
                }
            }
            if !forwarded.isEmpty {
                super.pressesEnded(forwarded, with: event)
            }
        }

        override func didUpdateFocus(
            in context: UIFocusUpdateContext,
            with coordinator: UIFocusAnimationCoordinator
        ) {
            super.didUpdateFocus(in: context, with: coordinator)
            onFocusChange(isFocused)
        }

        override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard gestureRecognizer === panGestureRecognizer,
                  isScrollingEnabled,
                  let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer
            else {
                return false
            }

            let velocity = panGestureRecognizer.velocity(in: self)
            return abs(velocity.x) > abs(velocity.y)
        }

        @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard isScrollingEnabled else { return }
            switch recognizer.state {
            case .began:
                onPanBegan()
            case .changed:
                onPanChanged(recognizer.translation(in: self).x)
            case .ended, .cancelled, .failed:
                onPanEnded()
            default:
                break
            }
        }
    }
#endif
