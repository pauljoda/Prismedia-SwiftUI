import Foundation

enum VideoSubtitleLanguageMatcher {
    static func preferredTrack(
        in tracks: [EntitySubtitle],
        terms: [SubtitlePreferenceTerm]
    ) -> EntitySubtitle? {
        let identifier = preferredIdentifier(
            in: tracks.map {
                VideoSubtitleSelectionCandidate(
                    id: $0.id,
                    language: $0.language,
                    label: $0.label
                )
            },
            terms: terms
        )
        return tracks.first { $0.id == identifier }
    }

    static func preferredIdentifier(
        in candidates: [VideoSubtitleSelectionCandidate],
        terms: [SubtitlePreferenceTerm]
    ) -> String? {
        let preferences = terms.compactMap { preference -> SubtitlePreferenceTerm? in
            let term = normalize(preference.term)
            guard !term.isEmpty, preference.weight > 0 else { return nil }
            return SubtitlePreferenceTerm(term: term, weight: preference.weight)
        }
        guard !preferences.isEmpty else { return candidates.first?.id }

        var best: (id: String, score: Int)?
        for candidate in candidates {
            let candidateTokens = tokens(for: candidate)
            let score = preferences.reduce(into: 0) { total, preference in
                if candidateTokens.contains(where: { matches(preference.term, token: $0) }) {
                    total += preference.weight
                }
            }
            if score > 0, best == nil || score > best!.score {
                best = (candidate.id, score)
            }
        }
        return best?.id
    }

    private static func matches(_ term: String, token: String) -> Bool {
        token.hasPrefix(term)
            || term.hasPrefix(token)
            || equivalentCodes[token] == term
            || equivalentCodes[term] == token
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
