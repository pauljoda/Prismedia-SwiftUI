#if os(tvOS)
    import AVKit
    import SwiftUI
    import UIKit

    /// SwiftUI-facing AVPlayerViewController adapter for tvOS system transport,
    /// media-selection menus, subtitles, and remote Menu dismissal.
    struct TVFullscreenPlayerController: UIViewControllerRepresentable {
        let controller: VideoPlaybackController
        let transportMenuSignature: String
        let assSubtitleContents: String?
        let subtitleContent: VideoSubtitleText?
        let subtitleAppearance: VideoSubtitleAppearance
        let onRequestDismiss: () -> Void

        func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

        func makeUIViewController(context: Context) -> AVPlayerViewController {
            let playerController = AVPlayerViewController()
            playerController.player = controller.player
            playerController.showsPlaybackControls = true
            playerController.delegate = context.coordinator
            context.coordinator.configure(
                playerController,
                controller: controller,
                transportMenuSignature: transportMenuSignature,
                assSubtitleContents: assSubtitleContents,
                subtitleContent: subtitleContent,
                subtitleAppearance: subtitleAppearance
            )
            return playerController
        }

        func updateUIViewController(
            _ playerController: AVPlayerViewController,
            context: Context
        ) {
            context.coordinator.parent = self
            if playerController.player !== controller.player {
                playerController.player = controller.player
            }
            context.coordinator.configure(
                playerController,
                controller: controller,
                transportMenuSignature: transportMenuSignature,
                assSubtitleContents: assSubtitleContents,
                subtitleContent: subtitleContent,
                subtitleAppearance: subtitleAppearance
            )
        }

        static func dismantleUIViewController(
            _ playerController: AVPlayerViewController,
            coordinator: Coordinator
        ) {
            coordinator.tearDownSubtitleOverlay()
            playerController.delegate = nil
            playerController.player = nil
        }

        @MainActor
        final class Coordinator: NSObject, AVPlayerViewControllerDelegate {
            var parent: TVFullscreenPlayerController
            private var subtitleHost: UIHostingController<VideoSubtitlePlaybackOverlay>?
            private var overlayBoundsObservation: NSKeyValueObservation?
            private var playerItemObservation: NSKeyValueObservation?
            private var presentationSizeObservation: NSKeyValueObservation?
            private var transportMenuSignature: String?

            init(parent: TVFullscreenPlayerController) {
                self.parent = parent
                super.init()
            }

            func configure(
                _ playerController: AVPlayerViewController,
                controller: VideoPlaybackController,
                transportMenuSignature: String,
                assSubtitleContents: String?,
                subtitleContent: VideoSubtitleText?,
                subtitleAppearance: VideoSubtitleAppearance
            ) {
                if self.transportMenuSignature != transportMenuSignature {
                    self.transportMenuSignature = transportMenuSignature
                    playerController.transportBarCustomMenuItems = transportMenus(for: controller)
                }
                configureSubtitleOverlay(
                    in: playerController,
                    controller: controller,
                    assContents: assSubtitleContents,
                    content: subtitleContent,
                    appearance: subtitleAppearance
                )
            }

            func playerViewControllerShouldDismiss(
                _ playerViewController: AVPlayerViewController
            ) -> Bool {
                if TVFullscreenPresentationPolicy.dismissalAction == .requestSwiftUICoverDismissal {
                    parent.onRequestDismiss()
                }
                return TVFullscreenPresentationPolicy.playerControllerDismissesItself
            }

            private func transportMenus(for controller: VideoPlaybackController) -> [UIMenuElement] {
                var menus: [UIMenuElement] = []

                if !controller.audioChoices.isEmpty {
                    let actions = controller.audioChoices.map { choice in
                        let action = UIAction(title: choice.title) { _ in
                            Task { await controller.selectAudio(id: choice.id) }
                        }
                        action.state = choice.id == controller.selectedAudioChoiceID ? .on : .off
                        return action
                    }
                    menus.append(
                        UIMenu(
                            title: "Audio",
                            image: UIImage(systemName: "speaker.wave.2"),
                            options: .singleSelection,
                            children: actions
                        ))
                }

                if !controller.subtitleChoices.isEmpty {
                    let actions = controller.subtitleChoices.map { choice in
                        let action = UIAction(title: choice.title) { _ in
                            Task { await controller.selectSubtitle(id: choice.id) }
                        }
                        action.state = choice.id == controller.selectedSubtitleChoiceID ? .on : .off
                        return action
                    }
                    menus.append(
                        UIMenu(
                            title: "Subtitles",
                            image: UIImage(systemName: "captions.bubble"),
                            options: .singleSelection,
                            children: actions
                        ))
                }

                let speeds: [(String, Float)] = [
                    ("0.5×", 0.5), ("1×", 1), ("1.25×", 1.25),
                    ("1.5×", 1.5), ("2×", 2),
                ]
                let speedActions = speeds.map { title, speed in
                    let action = UIAction(title: title) { _ in
                        controller.setPlaybackRate(speed)
                    }
                    action.state = controller.playbackRate == speed ? .on : .off
                    return action
                }
                menus.append(
                    UIMenu(
                        title: "Speed",
                        image: UIImage(systemName: "speedometer"),
                        options: .singleSelection,
                        children: speedActions
                    ))
                return menus
            }

            private func configureSubtitleOverlay(
                in playerController: AVPlayerViewController,
                controller: VideoPlaybackController,
                assContents: String?,
                content: VideoSubtitleText?,
                appearance: VideoSubtitleAppearance
            ) {
                let rootView = VideoSubtitlePlaybackOverlay(
                    assContents: assContents,
                    content: content,
                    appearance: appearance,
                    player: controller.player
                )

                if let subtitleHost {
                    subtitleHost.rootView = rootView
                    layoutSubtitleOverlay(in: playerController)
                    return
                }

                playerController.loadViewIfNeeded()
                guard let overlay = playerController.contentOverlayView else { return }

                let host = UIHostingController(rootView: rootView)
                host.view.backgroundColor = .clear
                host.view.isOpaque = false
                host.view.isUserInteractionEnabled = false
                playerController.addChild(host)
                overlay.addSubview(host.view)
                host.didMove(toParent: playerController)
                subtitleHost = host

                observeLayout(in: playerController, player: controller.player, overlay: overlay)
                layoutSubtitleOverlay(in: playerController)
            }

            fileprivate func tearDownSubtitleOverlay() {
                overlayBoundsObservation = nil
                playerItemObservation = nil
                presentationSizeObservation = nil
                subtitleHost?.willMove(toParent: nil)
                subtitleHost?.view.removeFromSuperview()
                subtitleHost?.removeFromParent()
                subtitleHost = nil
            }

            private func observeLayout(
                in playerController: AVPlayerViewController,
                player: AVPlayer,
                overlay: UIView
            ) {
                overlayBoundsObservation = overlay.observe(\.bounds, options: [.initial, .new]) {
                    [weak self, weak playerController] _, _ in
                    Task { @MainActor in
                        guard let self, let playerController else { return }
                        self.layoutSubtitleOverlay(in: playerController)
                    }
                }
                playerItemObservation = player.observe(\.currentItem, options: [.initial, .new]) {
                    [weak self, weak playerController] player, _ in
                    Task { @MainActor in
                        guard let self, let playerController else { return }
                        self.observePresentationSize(
                            of: player.currentItem,
                            in: playerController
                        )
                    }
                }
            }

            private func observePresentationSize(
                of item: AVPlayerItem?,
                in playerController: AVPlayerViewController
            ) {
                presentationSizeObservation = item?.observe(
                    \.presentationSize,
                    options: [.initial, .new]
                ) { [weak self, weak playerController] _, _ in
                    Task { @MainActor in
                        guard let self, let playerController else { return }
                        self.layoutSubtitleOverlay(in: playerController)
                    }
                }
                layoutSubtitleOverlay(in: playerController)
            }

            private func layoutSubtitleOverlay(in playerController: AVPlayerViewController) {
                guard let overlay = playerController.contentOverlayView,
                    let hostView = subtitleHost?.view,
                    !overlay.bounds.isEmpty
                else { return }

                let presentationSize = playerController.player?.currentItem?.presentationSize ?? .zero
                let frame =
                    presentationSize.width <= 0 || presentationSize.height <= 0
                    ? overlay.bounds
                    : AVMakeRect(aspectRatio: presentationSize, insideRect: overlay.bounds)
                hostView.frame = frame.integral
            }

        }
    }

    #if DEBUG
        #Preview("TV Fullscreen Player Controller") {
            let controller = VideoPlaybackController(
                videoID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                service: VideoPlaybackPreviewService()
            )

            TVFullscreenPlayerController(
                controller: controller,
                transportMenuSignature: "preview",
                assSubtitleContents: nil,
                subtitleContent: nil,
                subtitleAppearance: .default,
                onRequestDismiss: {}
            )
        }
    #endif
#endif
