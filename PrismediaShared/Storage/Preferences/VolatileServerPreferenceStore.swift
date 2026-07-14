#if DEBUG
    import Foundation

    /// Process-local server history for UI automation. A new application launch
    /// always starts at an empty server field instead of inheriting simulator
    /// UserDefaults from an earlier test run.
    @MainActor
    final class VolatileServerPreferenceStore: ServerPreferenceStoring {
        private var serverURL: URL?

        func load() -> URL? {
            serverURL
        }

        func save(_ serverURL: URL) {
            self.serverURL = serverURL
        }
    }
#endif
