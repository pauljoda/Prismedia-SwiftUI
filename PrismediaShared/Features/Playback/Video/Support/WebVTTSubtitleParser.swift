import Foundation

enum WebVTTSubtitleParser {
    private enum Error: Swift.Error { case invalidTiming }

    static func parse(_ contents: String) throws -> [VideoSubtitleCue] {
        let normalized = contents.replacingOccurrences(of: "\r\n", with: "\n")
        return try normalized.components(separatedBy: "\n\n").compactMap(parseBlock)
    }

    static func activeText(at time: Double, cues: [VideoSubtitleCue]) -> String? {
        cues.last(where: { $0.startTime <= time && time < $0.endTime })?.text
    }

    static func activeContent(at time: Double, cues: [VideoSubtitleCue]) -> VideoSubtitleText? {
        cues.last(where: { $0.startTime <= time && time < $0.endTime })?.content
    }

    private static func parseBlock(_ block: String) throws -> VideoSubtitleCue? {
        let lines = block.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        guard !lines.isEmpty, lines.first?.hasPrefix("WEBVTT") != true else { return nil }
        guard let timingIndex = lines.firstIndex(where: { $0.contains("-->") }) else { return nil }
        let times = lines[timingIndex].components(separatedBy: "-->")
        guard times.count == 2,
            let start = timestamp(times[0]),
            let endToken = times[1].trimmingCharacters(in: .whitespaces).split(separator: " ").first,
            let end = timestamp(String(endToken))
        else { throw Error.invalidTiming }
        let text = lines.dropFirst(timingIndex + 1).joined(separator: "\n")
        guard !text.isEmpty else { return nil }
        return .init(startTime: start, endTime: end, content: parseText(text))
    }

    private static func parseText(_ source: String) -> VideoSubtitleText {
        var runs: [VideoSubtitleTextRun] = []
        var buffer = ""
        var styles: [VideoSubtitleTextStyle] = []
        var index = source.startIndex

        func currentStyle() -> VideoSubtitleTextStyle {
            styles.reduce(into: []) { $0.formUnion($1) }
        }

        func flush() {
            guard !buffer.isEmpty else { return }
            let style = currentStyle()
            if let last = runs.last, last.style == style {
                runs[runs.count - 1] = .init(text: last.text + buffer, style: style)
            } else {
                runs.append(.init(text: buffer, style: style))
            }
            buffer = ""
        }

        while index < source.endIndex {
            if source[index] == "<", let close = source[index...].firstIndex(of: ">") {
                flush()
                updateStyles(
                    for: String(source[source.index(after: index)..<close]),
                    styles: &styles
                )
                index = source.index(after: close)
                continue
            }
            if source[index] == "&", let entity = decodedEntity(in: source, at: index) {
                buffer.append(entity.value)
                index = entity.nextIndex
                continue
            }
            buffer.append(source[index])
            index = source.index(after: index)
        }
        flush()
        return VideoSubtitleText(runs: runs)
    }

    private static func updateStyles(
        for rawTag: String,
        styles: inout [VideoSubtitleTextStyle]
    ) {
        let tag = rawTag.trimmingCharacters(in: .whitespacesAndNewlines)
        let isClosing = tag.hasPrefix("/")
        let body = isClosing ? String(tag.dropFirst()) : tag
        let end = body.firstIndex { $0 == "." || $0.isWhitespace } ?? body.endIndex
        let name = body[..<end].lowercased()
        let style: VideoSubtitleTextStyle? =
            switch name {
            case "b": .bold
            case "i": .italic
            case "u": .underline
            default: nil
            }
        guard let style else { return }
        if isClosing {
            guard let index = styles.lastIndex(of: style) else { return }
            styles.remove(at: index)
        } else {
            styles.append(style)
        }
    }

    private static func decodedEntity(
        in source: String,
        at ampersand: String.Index
    ) -> (value: Character, nextIndex: String.Index)? {
        let start = source.index(after: ampersand)
        guard let semicolon = source[start...].firstIndex(of: ";"),
            source.distance(from: start, to: semicolon) <= 12,
            let value = entityValue(String(source[start..<semicolon]))
        else { return nil }
        return (value, source.index(after: semicolon))
    }

    private static func entityValue(_ entity: String) -> Character? {
        switch entity.lowercased() {
        case "amp": return "&"
        case "lt": return "<"
        case "gt": return ">"
        case "nbsp": return "\u{00A0}"
        case "lrm": return "\u{200E}"
        case "rlm": return "\u{200F}"
        case "quot": return "\""
        case "apos": return "'"
        default:
            let radix = entity.lowercased().hasPrefix("#x") ? 16 : 10
            let digits = entity.dropFirst(radix == 16 ? 2 : 1)
            guard entity.hasPrefix("#"),
                let value = UInt32(digits, radix: radix),
                let scalar = UnicodeScalar(value)
            else { return nil }
            return Character(scalar)
        }
    }

    private static func timestamp(_ value: String) -> Double? {
        let components = value.trimmingCharacters(in: .whitespaces).split(separator: ":")
        guard components.count == 2 || components.count == 3 else { return nil }
        let seconds = Double(components.last ?? "") ?? 0
        let minutes = Double(components.dropLast().last ?? "") ?? 0
        let hours = components.count == 3 ? Double(components.first ?? "") ?? 0 : 0
        return hours * 3_600 + minutes * 60 + seconds
    }
}
