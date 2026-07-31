import Foundation

enum VideoNativeAudioStreamPolicy {
    static func preferredStreamIndex(
        container: String?,
        streams: [VideoPlaybackStream]
    ) -> Int? {
        let normalizedContainer = container?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard normalizedContainer == "mkv" || normalizedContainer == "matroska" else {
            return nil
        }

        let audioStreams = streams.filter {
            $0.type.caseInsensitiveCompare(PrismediaContractCodes.StreamKind.audio) == .orderedSame
        }
        let selectedLanguage = audioStreams.first(where: \.isDefault)?
            .language?
            .lowercased()
        let codecPriority = ["eac3": 0, "ac3": 1, "aac": 2]
        return audioStreams
            .filter {
                ($0.channels ?? 0) > 2
                    && codecPriority[$0.codec?.lowercased() ?? ""] != nil
                    && (selectedLanguage == nil || $0.language?.lowercased() == selectedLanguage)
            }
            .sorted {
                let leftPriority = codecPriority[$0.codec?.lowercased() ?? ""] ?? .max
                let rightPriority = codecPriority[$1.codec?.lowercased() ?? ""] ?? .max
                if leftPriority != rightPriority {
                    return leftPriority < rightPriority
                }
                if $0.channels != $1.channels {
                    return ($0.channels ?? 0) > ($1.channels ?? 0)
                }
                return $0.index < $1.index
            }
            .first?.index
    }
}
