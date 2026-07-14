#if os(tvOS)
    import AVKit
    import SwiftUI
    import UIKit

    /// SwiftUI-facing AVPlayerViewController adapter for tvOS system transport,
    /// media-selection menus, subtitles, and remote Menu dismissal.
    struct TVFullscreenPlayerController: UIViewControllerRepresentable {
        let controller: VideoPlaybackController
        let transportMenuSignature: String
        let subtitleContent: VideoSubtitleText?
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
                subtitleContent: subtitleContent
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
                subtitleContent: subtitleContent
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
            private weak var subtitleLabel: UILabel?
            private var transportMenuSignature: String?

            init(parent: TVFullscreenPlayerController) {
                self.parent = parent
                super.init()
            }

            func configure(
                _ playerController: AVPlayerViewController,
                controller: VideoPlaybackController,
                transportMenuSignature: String,
                subtitleContent: VideoSubtitleText?
            ) {
                if self.transportMenuSignature != transportMenuSignature {
                    self.transportMenuSignature = transportMenuSignature
                    playerController.transportBarCustomMenuItems = transportMenus(for: controller)
                }
                configureSubtitleOverlay(in: playerController, content: subtitleContent)
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
                content: VideoSubtitleText?
            ) {
                guard let overlay = playerController.contentOverlayView else { return }
                let label: UILabel
                if let subtitleLabel, subtitleLabel.superview === overlay {
                    label = subtitleLabel
                } else {
                    subtitleLabel?.removeFromSuperview()
                    label = UILabel()
                    label.translatesAutoresizingMaskIntoConstraints = false
                    label.numberOfLines = 0
                    label.textAlignment = .center
                    label.font = .preferredFont(forTextStyle: .title3)
                    label.textColor = .white
                    label.backgroundColor = UIColor.black.withAlphaComponent(0.72)
                    label.layer.cornerRadius = 8
                    label.layer.masksToBounds = true
                    overlay.addSubview(label)
                    let unobscured = playerController.unobscuredContentGuide
                    NSLayoutConstraint.activate([
                        label.centerXAnchor.constraint(equalTo: unobscured.centerXAnchor),
                        label.bottomAnchor.constraint(equalTo: unobscured.bottomAnchor, constant: -28),
                        label.widthAnchor.constraint(
                            lessThanOrEqualTo: unobscured.widthAnchor,
                            multiplier: 0.86
                        ),
                    ])
                    self.subtitleLabel = label
                }
                label.attributedText = content.map(attributedSubtitle)
                label.isHidden = content?.plainText.isEmpty != false
            }

            fileprivate func tearDownSubtitleOverlay() {
                subtitleLabel?.removeFromSuperview()
                subtitleLabel = nil
            }

            private func attributedSubtitle(_ content: VideoSubtitleText) -> NSAttributedString {
                let result = NSMutableAttributedString(string: "  ")
                let baseFont = UIFont.preferredFont(forTextStyle: .title3)
                for run in content.runs {
                    var traits: UIFontDescriptor.SymbolicTraits = []
                    if run.style.contains(.bold) { traits.insert(.traitBold) }
                    if run.style.contains(.italic) { traits.insert(.traitItalic) }
                    let descriptor =
                        baseFont.fontDescriptor.withSymbolicTraits(traits)
                        ?? baseFont.fontDescriptor
                    var attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont(descriptor: descriptor, size: baseFont.pointSize),
                        .foregroundColor: UIColor.white,
                    ]
                    if run.style.contains(.underline) {
                        attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
                    }
                    result.append(NSAttributedString(string: run.text, attributes: attributes))
                }
                result.append(NSAttributedString(string: "  "))
                return result
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
                subtitleContent: nil,
                onRequestDismiss: {}
            )
        }
    #endif
#endif
