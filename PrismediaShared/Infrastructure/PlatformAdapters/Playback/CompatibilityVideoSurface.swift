#if !os(tvOS) && (canImport(MobileVLCKit) || canImport(VLCKit))
    import SwiftUI

    #if canImport(UIKit)
        import UIKit

        struct CompatibilityVideoSurface: UIViewRepresentable {
            let controller: VideoPlaybackController
            let request: VideoCompatibilityPlaybackRequest

            func makeCoordinator() -> VLCPlaybackAdapter {
                VLCPlaybackAdapter(controller: controller)
            }

            func makeUIView(context: Context) -> UIView {
                let view = UIView()
                view.backgroundColor = .black
                context.coordinator.install(request, drawable: view)
                return view
            }

            func updateUIView(_ view: UIView, context: Context) {
                context.coordinator.update(request, drawable: view)
            }

            static func dismantleUIView(_ view: UIView, coordinator: VLCPlaybackAdapter) {
                coordinator.tearDown()
            }
        }
    #elseif canImport(AppKit)
        import AppKit

        struct CompatibilityVideoSurface: NSViewRepresentable {
            let controller: VideoPlaybackController
            let request: VideoCompatibilityPlaybackRequest

            func makeCoordinator() -> VLCPlaybackAdapter {
                VLCPlaybackAdapter(controller: controller)
            }

            func makeNSView(context: Context) -> NSView {
                let view = NSView()
                view.wantsLayer = true
                view.layer?.backgroundColor = NSColor.black.cgColor
                context.coordinator.install(request, drawable: view)
                return view
            }

            func updateNSView(_ view: NSView, context: Context) {
                context.coordinator.update(request, drawable: view)
            }

            static func dismantleNSView(_ view: NSView, coordinator: VLCPlaybackAdapter) {
                coordinator.tearDown()
            }
        }
    #endif

    #if DEBUG
        #Preview("Compatibility Video Surface") {
            let controller = VideoPlaybackController(
                videoID: UUID(uuidString: "A57450E8-AC6C-4930-9C1E-B3995675D702")!,
                service: VideoPlaybackPreviewService()
            )

            CompatibilityVideoSurface(
                controller: controller,
                request: VideoCompatibilityPlaybackRequest(
                    url: URL(fileURLWithPath: "/dev/null"),
                    resumeTime: 42,
                    playbackRate: 1,
                    audioStreams: []
                )
            )
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .background(.black)
        }
    #endif
#endif
