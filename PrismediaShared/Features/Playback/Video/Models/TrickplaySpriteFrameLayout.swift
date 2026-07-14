import CoreGraphics

struct TrickplaySpriteFrameLayout: Equatable {
    let scale: CGFloat
    let spriteSize: CGSize
    let offset: CGSize

    init(containerSize: CGSize, frame: TrickplayPlaylist.Frame) {
        let cropWidth = CGFloat(max(frame.crop.width, 1))
        let cropHeight = CGFloat(max(frame.crop.height, 1))
        let horizontalScale = max(containerSize.width, 0) / cropWidth
        let verticalScale = max(containerSize.height, 0) / cropHeight
        scale = max(horizontalScale, verticalScale)

        let renderedCropSize = CGSize(
            width: cropWidth * scale,
            height: cropHeight * scale
        )
        let centeredOverflow = CGSize(
            width: max(renderedCropSize.width - containerSize.width, 0) / 2,
            height: max(renderedCropSize.height - containerSize.height, 0) / 2
        )
        let spriteWidth = max(frame.imageWidth, frame.crop.x + frame.crop.width)
        let spriteHeight = max(frame.imageHeight, frame.crop.y + frame.crop.height)

        spriteSize = CGSize(
            width: CGFloat(spriteWidth) * scale,
            height: CGFloat(spriteHeight) * scale
        )
        offset = CGSize(
            width: -(CGFloat(frame.crop.x) * scale) - centeredOverflow.width,
            height: -(CGFloat(frame.crop.y) * scale) - centeredOverflow.height
        )
    }
}
