import Foundation

public enum VideoSubtitleDisplayStyle: String, CaseIterable, Identifiable, Sendable {
    case stylized
    case classic
    case outline

    public var id: String { rawValue }

    var label: String {
        switch self {
        case .stylized: "Stylized"
        case .classic: "Classic"
        case .outline: "Outline"
        }
    }

    var description: String {
        switch self {
        case .stylized: "Outline, shadow, and backing for readability."
        case .classic: "Flat black box with plain white text."
        case .outline: "White text with a black outline and no backing box."
        }
    }
}
