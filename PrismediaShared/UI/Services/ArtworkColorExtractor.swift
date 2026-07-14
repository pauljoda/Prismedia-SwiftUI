import CoreGraphics
import Foundation
import ImageIO

struct ArtworkColorExtractor: Sendable {
    private let maximumSampleDimension = 96
    private let clusterLimit = 8
    private let iterationLimit = 8

    func palette(imageData: Data) -> ArtworkPalette? {
        guard
            let source = CGImageSourceCreateWithData(
                imageData as CFData,
                [kCGImageSourceShouldCache: false] as CFDictionary
            )
        else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumSampleDimension,
        ]
        guard
            let image = CGImageSourceCreateThumbnailAtIndex(
                source,
                0,
                options as CFDictionary
            )
        else { return nil }
        return palette(image: image)
    }

    func palette(
        rgbaPixels: [UInt8],
        width: Int,
        height: Int
    ) -> ArtworkPalette? {
        guard width > 0, height > 0, rgbaPixels.count == width * height * 4 else {
            return nil
        }
        let samples = histogramSamples(
            rgbaPixels: rgbaPixels,
            width: width,
            height: height
        )
        guard !samples.colors.isEmpty else { return nil }
        let clusters = clusteredColors(
            samples.colors,
            weights: samples.weights,
            edgeWeights: samples.edgeWeights
        )
        return semanticPalette(
            colors: clusters.colors,
            weights: clusters.weights,
            edgeWeights: clusters.edgeWeights
        )
    }

    private func palette(image: CGImage) -> ArtworkPalette? {
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        let bitmapInfo =
            CGBitmapInfo.byteOrder32Big.rawValue
            | CGImageAlphaInfo.premultipliedLast.rawValue
        guard
            let context = CGContext(
                data: &pixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            )
        else { return nil }
        context.interpolationQuality = .low
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        unpremultiply(&pixels)
        return palette(rgbaPixels: pixels, width: width, height: height)
    }

    private func histogramSamples(
        rgbaPixels: [UInt8],
        width: Int,
        height: Int
    ) -> (colors: [SIMD3<Double>], weights: [Double], edgeWeights: [Double]) {
        var histogram: [Int: (red: Double, green: Double, blue: Double, weight: Double, edge: Double)] = [:]
        let edgeDepth = max(1, min(width, height) / 8)
        for y in 0..<height {
            for x in 0..<width {
                let offset = ((y * width) + x) * 4
                let alpha = Double(rgbaPixels[offset + 3]) / 255
                guard alpha >= 0.05 else { continue }
                let red = Double(rgbaPixels[offset]) / 255
                let green = Double(rgbaPixels[offset + 1]) / 255
                let blue = Double(rgbaPixels[offset + 2]) / 255
                let key =
                    (Int(rgbaPixels[offset] >> 3) << 10)
                    | (Int(rgbaPixels[offset + 1] >> 3) << 5)
                    | Int(rgbaPixels[offset + 2] >> 3)
                let isEdge =
                    x < edgeDepth || x >= width - edgeDepth
                    || y < edgeDepth || y >= height - edgeDepth
                var bin = histogram[key] ?? (0, 0, 0, 0, 0)
                bin.red += red * alpha
                bin.green += green * alpha
                bin.blue += blue * alpha
                bin.weight += alpha
                bin.edge += isEdge ? alpha : 0
                histogram[key] = bin
            }
        }

        var colors: [SIMD3<Double>] = []
        var weights: [Double] = []
        var edgeWeights: [Double] = []
        for key in histogram.keys.sorted() {
            guard let bin = histogram[key], bin.weight > 0 else { continue }
            colors.append(
                ArtworkColor(
                    red: bin.red / bin.weight,
                    green: bin.green / bin.weight,
                    blue: bin.blue / bin.weight
                ).perceptualComponents
            )
            weights.append(bin.weight)
            edgeWeights.append(bin.edge)
        }
        return (colors, weights, edgeWeights)
    }

    private func clusteredColors(
        _ colors: [SIMD3<Double>],
        weights: [Double],
        edgeWeights: [Double]
    ) -> (colors: [SIMD3<Double>], weights: [Double], edgeWeights: [Double]) {
        let clusterCount = min(clusterLimit, colors.count)
        var centers = initialCenters(
            colors,
            weights: weights,
            edgeWeights: edgeWeights,
            count: clusterCount
        )
        var assignments = [Int](repeating: 0, count: colors.count)

        for _ in 0..<iterationLimit {
            assignments = colors.map { nearestCenter(to: $0, centers: centers) }
            var sums = [SIMD3<Double>](repeating: .zero, count: centers.count)
            var totals = [Double](repeating: 0, count: centers.count)
            for index in colors.indices {
                let cluster = assignments[index]
                sums[cluster] += colors[index] * weights[index]
                totals[cluster] += weights[index]
            }
            var next = centers
            var movement = 0.0
            for index in centers.indices where totals[index] > 0 {
                next[index] = sums[index] / totals[index]
                movement = max(movement, squaredDistance(centers[index], next[index]))
            }
            centers = next
            if movement < 0.000_004 { break }
        }

        assignments = colors.map { nearestCenter(to: $0, centers: centers) }
        var clusterWeights = [Double](repeating: 0, count: centers.count)
        var clusterEdgeWeights = [Double](repeating: 0, count: centers.count)
        for index in assignments.indices {
            clusterWeights[assignments[index]] += weights[index]
            clusterEdgeWeights[assignments[index]] += edgeWeights[index]
        }
        let populated = centers.indices.filter { clusterWeights[$0] > 0 }
        return (
            populated.map { centers[$0] },
            populated.map { clusterWeights[$0] },
            populated.map { clusterEdgeWeights[$0] }
        )
    }

    private func initialCenters(
        _ colors: [SIMD3<Double>],
        weights: [Double],
        edgeWeights: [Double],
        count: Int
    ) -> [SIMD3<Double>] {
        let firstIndex =
            colors.indices.max {
                weights[$0] + (2 * edgeWeights[$0]) < weights[$1] + (2 * edgeWeights[$1])
            } ?? 0
        var centers = [colors[firstIndex]]
        while centers.count < count {
            let nextIndex =
                colors.indices.max { left, right in
                    seedScore(colors[left], weight: weights[left], centers: centers)
                        < seedScore(colors[right], weight: weights[right], centers: centers)
                } ?? firstIndex
            let candidate = colors[nextIndex]
            guard centers.allSatisfy({ squaredDistance($0, candidate) > 0.000_001 }) else {
                break
            }
            centers.append(candidate)
        }
        return centers
    }

    private func semanticPalette(
        colors: [SIMD3<Double>],
        weights: [Double],
        edgeWeights: [Double]
    ) -> ArtworkPalette? {
        guard !colors.isEmpty else { return nil }
        let totalWeight = weights.reduce(0, +)
        let totalEdgeWeight = max(edgeWeights.reduce(0, +), 1)
        let backgroundIndex =
            colors.indices.max { left, right in
                backgroundScore(
                    index: left,
                    weights: weights,
                    edgeWeights: edgeWeights,
                    totalWeight: totalWeight,
                    totalEdgeWeight: totalEdgeWeight
                )
                    < backgroundScore(
                        index: right,
                        weights: weights,
                        edgeWeights: edgeWeights,
                        totalWeight: totalWeight,
                        totalEdgeWeight: totalEdgeWeight
                    )
            } ?? 0
        let primaryIndex =
            bestAccentIndex(
                colors: colors,
                weights: weights,
                excluding: [backgroundIndex],
                referenceIndices: [backgroundIndex],
                totalWeight: totalWeight
            ) ?? backgroundIndex
        let secondaryIndex =
            bestAccentIndex(
                colors: colors,
                weights: weights,
                excluding: [backgroundIndex, primaryIndex],
                referenceIndices: [backgroundIndex, primaryIndex],
                totalWeight: totalWeight
            ) ?? backgroundIndex

        let background = ArtworkColor(
            perceptualComponents: colors[backgroundIndex]
        ).darkBackgroundColor()
        let primary = ArtworkColor(
            perceptualComponents: colors[primaryIndex]
        ).readable(over: background)
        var secondary = ArtworkColor(
            perceptualComponents: colors[secondaryIndex]
        ).readable(over: background)
        if secondary.perceptualDistance(to: primary) < 0.08 {
            var adjusted = secondary.perceptualComponents
            adjusted.x = max(0.72, min(adjusted.x, 0.82))
            adjusted.y *= 0.55
            adjusted.z *= 0.55
            secondary = ArtworkColor(perceptualComponents: adjusted).readable(over: background)
        }
        return ArtworkPalette(
            background: background,
            primary: primary,
            secondary: secondary
        )
    }

    private func bestAccentIndex(
        colors: [SIMD3<Double>],
        weights: [Double],
        excluding excluded: Set<Int>,
        referenceIndices: [Int],
        totalWeight: Double
    ) -> Int? {
        colors.indices
            .filter { !excluded.contains($0) && weights[$0] / totalWeight >= 0.02 }
            .max { left, right in
                accentScore(
                    index: left,
                    colors: colors,
                    weights: weights,
                    referenceIndices: referenceIndices,
                    totalWeight: totalWeight
                )
                    < accentScore(
                        index: right,
                        colors: colors,
                        weights: weights,
                        referenceIndices: referenceIndices,
                        totalWeight: totalWeight
                    )
            }
    }

    private func backgroundScore(
        index: Int,
        weights: [Double],
        edgeWeights: [Double],
        totalWeight: Double,
        totalEdgeWeight: Double
    ) -> Double {
        0.7 * (weights[index] / totalWeight)
            + 0.3 * (edgeWeights[index] / totalEdgeWeight)
    }

    private func accentScore(
        index: Int,
        colors: [SIMD3<Double>],
        weights: [Double],
        referenceIndices: [Int],
        totalWeight: Double
    ) -> Double {
        let color = colors[index]
        let chroma = hypot(color.y, color.z)
        let distance = referenceIndices.map { sqrt(squaredDistance(color, colors[$0])) }.min() ?? 0
        return sqrt(weights[index] / totalWeight) * (0.08 + chroma) * (0.2 + distance)
    }

    private func seedScore(
        _ color: SIMD3<Double>,
        weight: Double,
        centers: [SIMD3<Double>]
    ) -> Double {
        (centers.map { squaredDistance(color, $0) }.min() ?? 0) * sqrt(weight)
    }

    private func nearestCenter(
        to color: SIMD3<Double>,
        centers: [SIMD3<Double>]
    ) -> Int {
        centers.indices.min {
            squaredDistance(color, centers[$0]) < squaredDistance(color, centers[$1])
        } ?? 0
    }

    private func squaredDistance(_ left: SIMD3<Double>, _ right: SIMD3<Double>) -> Double {
        let difference = left - right
        return difference.x * difference.x + difference.y * difference.y + difference.z * difference.z
    }

    private func unpremultiply(_ pixels: inout [UInt8]) {
        for offset in stride(from: 0, to: pixels.count, by: 4) {
            let alpha = Int(pixels[offset + 3])
            guard alpha > 0, alpha < 255 else { continue }
            pixels[offset] = UInt8(min(255, (Int(pixels[offset]) * 255) / alpha))
            pixels[offset + 1] = UInt8(min(255, (Int(pixels[offset + 1]) * 255) / alpha))
            pixels[offset + 2] = UInt8(min(255, (Int(pixels[offset + 2]) * 255) / alpha))
        }
    }
}
