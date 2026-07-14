import SwiftUI

public struct ArtworkColor: Equatable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red.clamped(to: 0...1)
        self.green = green.clamped(to: 0...1)
        self.blue = blue.clamped(to: 0...1)
    }

    public var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue)
    }

    public func contrastRatio(with other: ArtworkColor) -> Double {
        let lighter = max(relativeLuminance, other.relativeLuminance)
        let darker = min(relativeLuminance, other.relativeLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    public func perceptualDistance(to other: ArtworkColor) -> Double {
        let difference = perceptualComponents - other.perceptualComponents
        return sqrt(difference.x * difference.x + difference.y * difference.y + difference.z * difference.z)
    }

    var perceptualComponents: SIMD3<Double> {
        let linearRed = Self.linearComponent(red)
        let linearGreen = Self.linearComponent(green)
        let linearBlue = Self.linearComponent(blue)

        let l =
            0.412_221_470_8 * linearRed + 0.536_332_536_3 * linearGreen
            + 0.051_445_992_9 * linearBlue
        let m =
            0.211_903_498_2 * linearRed + 0.680_699_545_1 * linearGreen
            + 0.107_396_956_6 * linearBlue
        let s =
            0.088_302_461_9 * linearRed + 0.281_718_837_6 * linearGreen
            + 0.629_978_700_5 * linearBlue

        let lRoot = cbrt(l)
        let mRoot = cbrt(m)
        let sRoot = cbrt(s)
        return SIMD3(
            0.210_454_255_3 * lRoot + 0.793_617_785 * mRoot - 0.004_072_046_8 * sRoot,
            1.977_998_495_1 * lRoot - 2.428_592_205 * mRoot + 0.450_593_709_9 * sRoot,
            0.025_904_037_1 * lRoot + 0.782_771_766_2 * mRoot - 0.808_675_766 * sRoot
        )
    }

    init(perceptualComponents value: SIMD3<Double>) {
        let lRoot = value.x + 0.396_337_777_4 * value.y + 0.215_803_757_3 * value.z
        let mRoot = value.x - 0.105_561_345_8 * value.y - 0.063_854_172_8 * value.z
        let sRoot = value.x - 0.089_484_177_5 * value.y - 1.291_485_548 * value.z

        let l = lRoot * lRoot * lRoot
        let m = mRoot * mRoot * mRoot
        let s = sRoot * sRoot * sRoot
        let linearRed = 4.076_741_662_1 * l - 3.307_711_591_3 * m + 0.230_969_929_2 * s
        let linearGreen = -1.268_438_004_6 * l + 2.609_757_401_1 * m - 0.341_319_396_5 * s
        let linearBlue = -0.004_196_086_3 * l - 0.703_418_614_7 * m + 1.707_614_701 * s

        self.init(
            red: Self.encodedComponent(linearRed),
            green: Self.encodedComponent(linearGreen),
            blue: Self.encodedComponent(linearBlue)
        )
    }

    func darkBackgroundColor() -> ArtworkColor {
        var value = perceptualComponents
        let chroma = hypot(value.y, value.z)
        if chroma > 0.14 {
            let scale = 0.14 / chroma
            value.y *= scale
            value.z *= scale
        }
        value.x = min(max(value.x * 0.42, 0.1), 0.24)
        return ArtworkColor(perceptualComponents: value)
    }

    func readable(over background: ArtworkColor, minimumContrast: Double = 4.5) -> ArtworkColor {
        if contrastRatio(with: background) >= minimumContrast,
            relativeLuminance > background.relativeLuminance
        {
            return self
        }

        let source = perceptualComponents
        var lightness = max(source.x, 0.56)
        while lightness <= 1 {
            let candidate = ArtworkColor(
                perceptualComponents: SIMD3(lightness, source.y, source.z)
            )
            if candidate.contrastRatio(with: background) >= minimumContrast {
                return candidate
            }
            lightness += 0.02
        }
        return ArtworkColor(red: 1, green: 1, blue: 1)
    }

    private var relativeLuminance: Double {
        0.2126 * Self.linearComponent(red)
            + 0.7152 * Self.linearComponent(green)
            + 0.0722 * Self.linearComponent(blue)
    }

    private static func linearComponent(_ value: Double) -> Double {
        value <= 0.04045
            ? value / 12.92
            : pow((value + 0.055) / 1.055, 2.4)
    }

    private static func encodedComponent(_ value: Double) -> Double {
        value <= 0.003_130_8
            ? 12.92 * value
            : 1.055 * pow(value, 1 / 2.4) - 0.055
    }
}

extension Double {
    fileprivate func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
