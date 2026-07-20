import Foundation

public enum VideoPlaybackEngine: String, CaseIterable, Codable, Identifiable, Sendable {
    case automatic
    case native
    case vlc

    public var id: String { rawValue }

    static let defaultChoice = VideoPlaybackEngine.automatic
    static let userSelectableCases: [VideoPlaybackEngine] = [.automatic, .native]

    var label: String {
        switch self {
        case .automatic: "Prismedia"
        case .native: "Native"
        case .vlc: "VLC"
        }
    }

    var explanation: String {
        switch self {
        case .automatic:
            #if os(iOS)
                "Uses native playback when possible and Prismedia’s compatibility engine only when the source requires it. Picture in Picture is available while the native engine is active."
            #else
                "Uses native playback when possible and Prismedia’s compatibility engine only when the source requires it."
            #endif
        case .native:
            #if os(iOS)
                "Always uses Apple’s player, including Picture in Picture, and lets the server adapt unsupported files."
            #else
                "Always uses Apple’s player and lets the server adapt unsupported files."
            #endif
        case .vlc: "Prefers direct playback through VLC for broad format support. Picture in Picture is unavailable."
        }
    }
}
