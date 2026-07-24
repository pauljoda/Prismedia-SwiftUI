import CoreGraphics
import CoreImage
import Foundation

actor ArtworkExtensionImagePipeline {
    static let shared = ArtworkExtensionImagePipeline()

    private static let effectVersion = 1

    private let context: CIContext
    private let byteCostLimit: Int
    private var images: [String: CGImage] = [:]
    private var costs: [String: Int] = [:]
    private var recency: [String] = []
    private var byteCost = 0

    init(
        context: CIContext = CIContext(),
        byteCostLimit: Int = 32 * 1_024 * 1_024
    ) {
        self.context = context
        self.byteCostLimit = max(0, byteCostLimit)
    }

    func image(
        for url: URL,
        artworkLoader: any RemoteArtworkLoading,
        sourceAspectRatio: Double,
        outputAspectRatio: Double,
        maxPixelSize: Int
    ) async -> CGImage? {
        let key = cacheKey(
            url: url,
            sourceAspectRatio: sourceAspectRatio,
            outputAspectRatio: outputAspectRatio,
            maxPixelSize: maxPixelSize
        )
        if let cached = cachedImage(for: key) {
            return cached
        }

        let source: CGImage
        if let cached = artworkLoader.cachedImage(for: url, maxPixelSize: maxPixelSize) {
            source = cached
        } else {
            guard let loaded = try? await artworkLoader.image(for: url, maxPixelSize: maxPixelSize)
            else { return nil }
            source = loaded
        }

        if let cached = cachedImage(for: key) {
            return cached
        }
        guard
            let rendered = render(
                source,
                sourceAspectRatio: sourceAspectRatio,
                outputAspectRatio: outputAspectRatio,
                maxPixelSize: maxPixelSize
            )
        else { return nil }

        store(rendered, for: key)
        return rendered
    }

    func clearCache() {
        images.removeAll()
        costs.removeAll()
        recency.removeAll()
        byteCost = 0
    }

    private func render(
        _ source: CGImage,
        sourceAspectRatio: Double,
        outputAspectRatio: Double,
        maxPixelSize: Int
    ) -> CGImage? {
        guard sourceAspectRatio > 0, outputAspectRatio > 0, maxPixelSize > 0 else {
            return nil
        }

        let outputWidth = max(1, min(maxPixelSize, source.width))
        let outputHeight = max(1, Int((Double(outputWidth) / outputAspectRatio).rounded(.up)))
        let outputRect = CGRect(x: 0, y: 0, width: outputWidth, height: outputHeight)
        let sourceImage = CIImage(cgImage: source)

        let background =
            aspectFill(sourceImage, in: outputRect)
            .clampedToExtent()
            .applyingFilter(
                "CIGaussianBlur",
                parameters: [kCIInputRadiusKey: max(10, Double(outputWidth) * 0.035)]
            )
            .cropped(to: outputRect)
            .applyingFilter(
                "CIColorControls",
                parameters: [
                    kCIInputBrightnessKey: -0.08,
                    kCIInputSaturationKey: 0.82,
                ]
            )

        let artworkHeight = min(
            CGFloat(outputHeight),
            CGFloat(outputWidth) / CGFloat(sourceAspectRatio)
        )
        let artworkRect = CGRect(
            x: 0,
            y: CGFloat(outputHeight) - artworkHeight,
            width: CGFloat(outputWidth),
            height: artworkHeight
        )
        let foreground = aspectFill(sourceImage, in: artworkRect)
        let reflectionTransform = CGAffineTransform(
            a: 1,
            b: 0,
            c: 0,
            d: -1,
            tx: 0,
            ty: artworkRect.minY * 2
        )
        let reflection =
            foreground
            .transformed(by: reflectionTransform)
            .applyingFilter(
                "CIGaussianBlur",
                parameters: [kCIInputRadiusKey: max(8, Double(outputWidth) * 0.025)]
            )
            .cropped(to: outputRect)
            .applyingFilter(
                "CIColorControls",
                parameters: [kCIInputBrightnessKey: -0.1]
            )

        guard
            let reflectionMask = CIFilter(
                name: "CILinearGradient",
                parameters: [
                    "inputPoint0": CIVector(x: outputRect.midX, y: artworkRect.minY),
                    "inputColor0": CIColor.white,
                    "inputPoint1": CIVector(x: outputRect.midX, y: outputRect.minY),
                    "inputColor1": CIColor.black,
                ]
            )?.outputImage?.cropped(to: outputRect)
        else { return nil }

        let extended =
            reflection
            .applyingFilter(
                "CIBlendWithMask",
                parameters: [
                    kCIInputBackgroundImageKey: background,
                    kCIInputMaskImageKey: reflectionMask,
                ]
            )
            .cropped(to: outputRect)
        let composition = foreground.composited(over: extended).cropped(to: outputRect)

        return context.createCGImage(composition, from: outputRect)
    }

    private func aspectFill(_ image: CIImage, in rect: CGRect) -> CIImage {
        let extent = image.extent
        guard extent.width > 0, extent.height > 0 else { return image }

        let scale = max(rect.width / extent.width, rect.height / extent.height)
        let scaled = image.transformed(
            by: CGAffineTransform(scaleX: scale, y: scale)
        )
        let translation = CGAffineTransform(
            translationX: rect.midX - scaled.extent.midX,
            y: rect.midY - scaled.extent.midY
        )
        return scaled.transformed(by: translation).cropped(to: rect)
    }

    private func cacheKey(
        url: URL,
        sourceAspectRatio: Double,
        outputAspectRatio: Double,
        maxPixelSize: Int
    ) -> String {
        [
            String(Self.effectVersion),
            String(maxPixelSize),
            String(sourceAspectRatio),
            String(outputAspectRatio),
            url.absoluteString,
        ].joined(separator: "|")
    }

    private func cachedImage(for key: String) -> CGImage? {
        guard let image = images[key] else { return nil }
        recency.removeAll { $0 == key }
        recency.append(key)
        return image
    }

    private func store(_ image: CGImage, for key: String) {
        let cost = image.bytesPerRow.multipliedReportingOverflow(by: image.height)
        guard !cost.overflow, cost.partialValue <= byteCostLimit else { return }

        removeImage(for: key)
        images[key] = image
        costs[key] = cost.partialValue
        recency.append(key)
        byteCost += cost.partialValue

        while byteCost > byteCostLimit, let leastRecentKey = recency.first {
            removeImage(for: leastRecentKey)
        }
    }

    private func removeImage(for key: String) {
        images[key] = nil
        byteCost -= costs.removeValue(forKey: key) ?? 0
        recency.removeAll { $0 == key }
    }
}
