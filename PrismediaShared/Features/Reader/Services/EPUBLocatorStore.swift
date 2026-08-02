import Foundation

public struct EPUBLocatorStore: @unchecked Sendable {
    private static let keyPrefix = "prismedia.reader.epub.locator.v1."
    private static let checkpointKeyPrefix = "prismedia.reader.epub.locator-checkpoint.v1."
    private static let chapterKeyPrefix = "prismedia.reader.epub.chapter-locators.v1."

    private let defaults: UserDefaults?

    public static var standard: Self {
        Self(defaults: .standard)
    }

    public static var disabled: Self {
        Self(defaults: nil)
    }

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    private init(defaults: UserDefaults?) {
        self.defaults = defaults
    }

    public func load(bookID: UUID) -> String? {
        defaults?.string(forKey: key(bookID))
    }

    public func loadCheckpoint(bookID: UUID) -> EPUBLocatorCheckpoint? {
        guard let defaults else { return nil }
        if let data = defaults.data(forKey: checkpointKey(bookID)),
            let checkpoint = try? JSONDecoder().decode(EPUBLocatorCheckpoint.self, from: data)
        {
            return checkpoint
        }
        return defaults.string(forKey: key(bookID)).map {
            EPUBLocatorCheckpoint(locator: $0, savedAt: .distantPast)
        }
    }

    public func save(
        _ locator: String,
        bookID: UUID,
        savedAt: Date = .now
    ) {
        guard let defaults else { return }
        defaults.set(locator, forKey: key(bookID))
        let checkpoint = EPUBLocatorCheckpoint(locator: locator, savedAt: savedAt)
        if let data = try? JSONEncoder().encode(checkpoint) {
            defaults.set(data, forKey: checkpointKey(bookID))
        }
    }

    public func load(bookID: UUID, chapterLocation: String) -> String? {
        chapterLocators(bookID: bookID)[chapterKey(chapterLocation)]
    }

    public func save(
        _ locator: String,
        bookID: UUID,
        chapterLocation: String,
        savedAt: Date = .now
    ) {
        guard let defaults else { return }
        var locators = chapterLocators(bookID: bookID)
        locators[chapterKey(chapterLocation)] = locator
        defaults.set(locators, forKey: chaptersKey(bookID))
        save(locator, bookID: bookID, savedAt: savedAt)
    }

    private func key(_ bookID: UUID) -> String {
        Self.keyPrefix + bookID.uuidString.lowercased()
    }

    private func chaptersKey(_ bookID: UUID) -> String {
        Self.chapterKeyPrefix + bookID.uuidString.lowercased()
    }

    private func checkpointKey(_ bookID: UUID) -> String {
        Self.checkpointKeyPrefix + bookID.uuidString.lowercased()
    }

    private func chapterLocators(bookID: UUID) -> [String: String] {
        defaults?.dictionary(forKey: chaptersKey(bookID)) as? [String: String] ?? [:]
    }

    private func chapterKey(_ location: String) -> String {
        let resource = location.split(separator: "#", maxSplits: 1).first.map(String.init) ?? location
        return (resource.removingPercentEncoding ?? resource).lowercased()
    }
}
