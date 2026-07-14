import Foundation

/// Keeps the last verified server independently from the login token. This is
/// intentionally UserDefaults-backed on every platform so a signed-out Apple TV
/// can return to the same server after an app update or token expiry.
@MainActor
public protocol ServerPreferenceStoring {
    func load() -> URL?
    func save(_ serverURL: URL)
}
