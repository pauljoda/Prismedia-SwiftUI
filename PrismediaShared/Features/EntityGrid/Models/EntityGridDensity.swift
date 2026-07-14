import CoreGraphics
import Foundation

public enum EntityGridDensity: String, CaseIterable, Codable, Identifiable, Sendable {
    case compact
    case standard
    case large

    public var id: Self { self }

    public var label: String {
        switch self {
        case .compact: "Compact"
        case .standard: "Standard"
        case .large: "Large"
        }
    }

    public func minimumColumnWidth(default defaultWidth: CGFloat) -> CGFloat {
        switch self {
        case .compact: defaultWidth * 0.8
        case .standard: defaultWidth
        case .large: defaultWidth * 1.3
        }
    }
}
