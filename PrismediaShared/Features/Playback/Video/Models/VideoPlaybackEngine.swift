import Foundation

public enum VideoPlaybackEngine: String, CaseIterable, Codable, Identifiable, Sendable {
    case automatic
    case native
    case vlc

    public var id: String { rawValue }

    var label: String {
        switch self {
        case .automatic: "Automatic"
        case .native: "Native"
        case .vlc: "VLC"
        }
    }

    var explanation: String {
        switch self {
        case .automatic: "Chooses the fastest compatible player for each video."
        case .native: "Uses Apple’s player, including Picture in Picture, and lets the server adapt unsupported files."
        case .vlc: "Prefers direct playback through VLC for broad format support. Picture in Picture is unavailable."
        }
    }
}
