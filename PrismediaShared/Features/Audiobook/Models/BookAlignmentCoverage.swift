import Foundation

/// How much of a Book's readable and audio content the server's alignment pairs.
public struct BookAlignmentCoverage: Equatable, Hashable, Sendable {
    // MARK: - Variables

    public let readableCount: Int
    public let audioWindowCount: Int
    public let pairedCount: Int
    public let manualCount: Int
    public let automaticCount: Int
    public let readableOnlyCount: Int
    public let audioOnlyCount: Int
    public let pairedReadableFraction: Double
    public let pairedAudioSeconds: Double
    public let totalAudioSeconds: Double

    // MARK: - Initializers

    public init(
        readableCount: Int = 0,
        audioWindowCount: Int = 0,
        pairedCount: Int = 0,
        manualCount: Int = 0,
        automaticCount: Int = 0,
        readableOnlyCount: Int = 0,
        audioOnlyCount: Int = 0,
        pairedReadableFraction: Double = 0,
        pairedAudioSeconds: Double = 0,
        totalAudioSeconds: Double = 0
    ) {
        self.readableCount = readableCount
        self.audioWindowCount = audioWindowCount
        self.pairedCount = pairedCount
        self.manualCount = manualCount
        self.automaticCount = automaticCount
        self.readableOnlyCount = readableOnlyCount
        self.audioOnlyCount = audioOnlyCount
        self.pairedReadableFraction = pairedReadableFraction
        self.pairedAudioSeconds = pairedAudioSeconds
        self.totalAudioSeconds = totalAudioSeconds
    }
}

extension BookAlignmentCoverage: Decodable {
    private enum CodingKeys: String, CodingKey {
        case readableCount, audioWindowCount, pairedCount, manualCount, automaticCount
        case readableOnlyCount, audioOnlyCount, pairedReadableFraction, pairedAudioSeconds, totalAudioSeconds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        readableCount = try container.decodeFlexibleIntIfPresent(forKey: .readableCount) ?? 0
        audioWindowCount = try container.decodeFlexibleIntIfPresent(forKey: .audioWindowCount) ?? 0
        pairedCount = try container.decodeFlexibleIntIfPresent(forKey: .pairedCount) ?? 0
        manualCount = try container.decodeFlexibleIntIfPresent(forKey: .manualCount) ?? 0
        automaticCount = try container.decodeFlexibleIntIfPresent(forKey: .automaticCount) ?? 0
        readableOnlyCount = try container.decodeFlexibleIntIfPresent(forKey: .readableOnlyCount) ?? 0
        audioOnlyCount = try container.decodeFlexibleIntIfPresent(forKey: .audioOnlyCount) ?? 0
        pairedReadableFraction = try container.decodeFlexibleDoubleIfPresent(forKey: .pairedReadableFraction) ?? 0
        pairedAudioSeconds = try container.decodeFlexibleDoubleIfPresent(forKey: .pairedAudioSeconds) ?? 0
        totalAudioSeconds = try container.decodeFlexibleDoubleIfPresent(forKey: .totalAudioSeconds) ?? 0
    }
}
