import SwiftUI

struct SpriteFrameView: View {
    let frame: TrickplayPlaylist.Frame
    let imageURL: URL
    @State private var spriteImage: Image?

    var body: some View {
        GeometryReader { geometry in
            if let spriteImage {
                let scale = geometry.size.height / CGFloat(frame.crop.height)
                spriteImage
                    .resizable()
                    .frame(
                        width: CGFloat(frame.imageWidth) * scale,
                        height: CGFloat(frame.imageHeight) * scale,
                        alignment: .topLeading
                    )
                    .offset(
                        x: -CGFloat(frame.crop.x) * scale,
                        y: -CGFloat(frame.crop.y) * scale
                    )
            } else {
                Color(white: 0.08)
            }
        }
        .clipped()
        .task(id: imageURL) {
            guard let data = try? await RemoteArtworkPipeline.shared.data(for: imageURL) else { return }
            spriteImage = await TrickplaySpriteImageCache.shared.image(
                for: imageURL,
                data: data
            )
        }
    }
}

#if DEBUG
    #Preview("Sprite Frame") {
        SpriteFrameView(
            frame: TrickplayPlaylist.Frame(
                startTime: 0,
                imageURL: URL(string: "data:image/png;base64,")!,
                crop: .init(x: 0, y: 0, width: 160, height: 90),
                imageWidth: 160,
                imageHeight: 90
            ),
            imageURL: URL(string: "data:image/png;base64,")!
        )
        .frame(width: 160, height: 90)
    }
#endif
