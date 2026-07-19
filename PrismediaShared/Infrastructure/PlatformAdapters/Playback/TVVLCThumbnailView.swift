#if os(tvOS)
    import SwiftUI
    @preconcurrency import TVVLCKit
    import UIKit

    struct TVVLCThumbnailView: UIViewRepresentable {
        let url: URL
        let position: Double

        func makeCoordinator() -> Coordinator { Coordinator() }

        func makeUIView(context: Context) -> UIImageView {
            let imageView = UIImageView()
            imageView.backgroundColor = .black
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            return imageView
        }

        func updateUIView(_ imageView: UIImageView, context: Context) {
            context.coordinator.requestThumbnail(
                url: url,
                position: max(0, min(1, position)),
                imageView: imageView
            )
        }

        static func dismantleUIView(_ imageView: UIImageView, coordinator: Coordinator) {
            coordinator.cancel()
        }

        @MainActor
        final class Coordinator: NSObject, VLCMediaThumbnailerDelegate {
            private weak var imageView: UIImageView?
            private var pendingTask: Task<Void, Never>?
            private var thumbnailer: VLCMediaThumbnailer?
            private var requestedURL: URL?
            private var requestedPosition = -1.0

            func requestThumbnail(url: URL, position: Double, imageView: UIImageView) {
                self.imageView = imageView
                guard requestedURL != url || abs(requestedPosition - position) >= 0.001 else { return }
                requestedURL = url
                requestedPosition = position
                pendingTask?.cancel()
                pendingTask = Task { [weak self] in
                    try? await Task.sleep(for: .milliseconds(140))
                    guard !Task.isCancelled, let self else { return }
                    let media = VLCMedia(url: url)
                    let thumbnailer = VLCMediaThumbnailer(media: media, andDelegate: self)
                    thumbnailer.thumbnailWidth = 480
                    thumbnailer.thumbnailHeight = 270
                    thumbnailer.snapshotPosition = Float(position)
                    self.thumbnailer = thumbnailer
                    thumbnailer.fetchThumbnail()
                }
            }

            func cancel() {
                pendingTask?.cancel()
                pendingTask = nil
                thumbnailer?.delegate = nil
                thumbnailer = nil
                imageView = nil
            }

            func mediaThumbnailerDidTimeOut(_ mediaThumbnailer: VLCMediaThumbnailer) {
                guard mediaThumbnailer === thumbnailer else { return }
                thumbnailer = nil
            }

            func mediaThumbnailer(
                _ mediaThumbnailer: VLCMediaThumbnailer,
                didFinishThumbnail thumbnail: CGImage
            ) {
                guard mediaThumbnailer === thumbnailer else { return }
                imageView?.image = UIImage(cgImage: thumbnail)
                thumbnailer = nil
            }
        }
    }

    #if DEBUG
        #Preview("TV VLC Thumbnail") {
            TVVLCThumbnailView(
                url: URL(fileURLWithPath: "/dev/null"),
                position: 0.5
            )
            .frame(width: 480, height: 270)
            .background(Color.black)
        }
    #endif
#endif
