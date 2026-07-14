import CoreGraphics

struct EntityImageVideoProgressLayout: Sendable {
    static func fittedMediaFrame(
        containerSize: CGSize,
        mediaSize: CGSize
    ) -> CGRect? {
        guard isValid(containerSize), isValid(mediaSize) else { return nil }

        let scale = min(
            containerSize.width / mediaSize.width,
            containerSize.height / mediaSize.height
        )
        let fittedSize = CGSize(
            width: mediaSize.width * scale,
            height: mediaSize.height * scale
        )
        return CGRect(
            x: (containerSize.width - fittedSize.width) / 2,
            y: (containerSize.height - fittedSize.height) / 2,
            width: fittedSize.width,
            height: fittedSize.height
        )
    }

    private static func isValid(_ size: CGSize) -> Bool {
        size.width.isFinite && size.height.isFinite
            && size.width > 0 && size.height > 0
    }
}
