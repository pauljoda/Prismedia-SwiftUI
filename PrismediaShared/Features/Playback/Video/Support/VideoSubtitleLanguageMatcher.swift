import Foundation

enum VideoSubtitleLanguageMatcher {
    static func preferredTrack(
        in tracks: [EntitySubtitle],
        languages: [String]
    ) -> EntitySubtitle? {
        let identifier = preferredIdentifier(
            in: tracks.map {
                VideoSubtitleSelectionCandidate(
                    id: $0.id,
                    language: $0.language,
                    label: $0.label
                )
            },
            languages: languages
        )
        return tracks.first { $0.id == identifier }
    }

    static func preferredIdentifier(
        in candidates: [VideoSubtitleSelectionCandidate],
        languages: [String]
    ) -> String? {
        let preferences = languages.map(normalize).filter { !$0.isEmpty }
        guard !preferences.isEmpty else { return candidates.first?.id }

        for preference in preferences {
            if let exact = candidates.first(where: { tokens(for: $0).contains(preference) }) {
                return exact.id
            }
            if let prefix = candidates.first(where: { candidate in
                tokens(for: candidate).contains { token in
                    token.hasPrefix(preference) || preference.hasPrefix(token)
                }
            }) {
                return prefix.id
            }
            if let equivalent = candidates.first(where: { candidate in
                tokens(for: candidate).contains {
                    equivalentCodes[$0] == preference || equivalentCodes[preference] == $0
                }
            }) {
                return equivalent.id
            }
        }
        return nil
    }

    private static func tokens(for candidate: VideoSubtitleSelectionCandidate) -> Set<String> {
        Set([candidate.language, candidate.label].compactMap { $0 }.flatMap(tokens))
    }

    private static func tokens(for value: String) -> [String] {
        let normalized = normalize(value)
        guard !normalized.isEmpty else { return [] }
        let words = normalized.split { character in
            character.isWhitespace || "-_/,".contains(character)
        }
        let values = [normalized] + words.map(String.init)
        return values.flatMap { token in
            if let languageCode = languageNames[token] {
                return [token, languageCode]
            }
            return [token]
        }
    }

    private static func normalize(_ value: String) -> String {
        value.lowercased()
            .replacingOccurrences(of: #"\s*[\(\[][^\)\]]*[\)\]]\s*"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let equivalentCodes = [
        "en": "eng", "eng": "en", "ja": "jpn", "jpn": "ja",
        "es": "spa", "spa": "es", "fr": "fra", "fra": "fr",
        "de": "deu", "deu": "de", "zh": "zho", "zho": "zh",
        "ko": "kor", "kor": "ko", "pt": "por", "por": "pt",
        "ru": "rus", "rus": "ru", "it": "ita", "ita": "it",
        "nl": "nld", "nld": "nl", "ar": "ara", "ara": "ar",
        "hi": "hin", "hin": "hi",
    ]

    private static let languageNames = [
        "english": "en", "japanese": "ja", "spanish": "es", "french": "fr",
        "german": "de", "chinese": "zh", "korean": "ko", "portuguese": "pt",
        "russian": "ru", "italian": "it", "dutch": "nl", "arabic": "ar",
        "hindi": "hi",
    ]
}
