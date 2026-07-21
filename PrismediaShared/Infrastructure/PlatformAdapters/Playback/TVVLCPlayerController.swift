#if os(tvOS)
    import SwiftUI
    import UIKit

    struct TVVLCPlayerController: UIViewControllerRepresentable {
        let request: VideoCompatibilityPlaybackRequest
        let controller: VideoPlaybackController

        func makeCoordinator() -> VLCPlaybackAdapter {
            VLCPlaybackAdapter(controller: controller)
        }

        func makeUIViewController(context: Context) -> UIViewController {
            let viewController = UIViewController()
            viewController.view.backgroundColor = .black
            context.coordinator.install(request, drawable: viewController.view)
            return viewController
        }

        func updateUIViewController(
            _ viewController: UIViewController,
            context: Context
        ) {
            context.coordinator.update(request, drawable: viewController.view)
        }

        static func dismantleUIViewController(
            _ viewController: UIViewController,
            coordinator: VLCPlaybackAdapter
        ) {
            coordinator.tearDown()
        }
    }

    #if DEBUG
        #Preview("TV VLC Player Adapter") {
            TVVLCPlayerController(
                request: VideoCompatibilityPlaybackRequest(
                    url: URL(fileURLWithPath: "/dev/null"),
                    resumeTime: 0,
                    playbackRate: 1,
                    audioStreams: []
                ),
                controller: VideoPlaybackController(
                    videoID: UUID(uuidString: "A57450E8-AC6C-4930-9C1E-B3995675D702")!,
                    service: VideoPlaybackPreviewService()
                )
            )
        }
    #endif
#endif
