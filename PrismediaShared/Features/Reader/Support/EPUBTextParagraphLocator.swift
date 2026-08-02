import Foundation

/// Resolves semantic paragraph anchors against the plain text produced by a native EPUB renderer.
struct EPUBTextParagraphLocator: Sendable {
    func anchor(in text: String, characterIndex: Int) -> EPUBParagraphAnchor? {
        let paragraphs = paragraphRanges(in: text)
        guard !paragraphs.isEmpty else { return nil }
        let boundedIndex = min(max(characterIndex, 0), max(0, (text as NSString).length - 1))
        let paragraphIndex = paragraphs.firstIndex {
            NSLocationInRange(boundedIndex, $0.range)
                || boundedIndex == NSMaxRange($0.range)
        } ?? paragraphs.indices.last
        guard let paragraphIndex else { return nil }
        return EPUBParagraphAnchor(
            index: paragraphIndex,
            text: paragraphs[paragraphIndex].text
        )
    }

    func characterIndex(for anchor: EPUBParagraphAnchor, in text: String) -> Int? {
        let paragraphs = paragraphRanges(in: text)
        guard !paragraphs.isEmpty else { return nil }
        let normalizedText = anchor.text.map(normalized)
        if paragraphs.indices.contains(anchor.index) {
            let indexed = paragraphs[anchor.index]
            if normalizedText == nil || indexed.text == normalizedText {
                return indexed.range.location
            }
        }
        guard let normalizedText, !normalizedText.isEmpty else { return nil }
        return paragraphs.first(where: { $0.text == normalizedText })?.range.location
    }

    private func paragraphRanges(in text: String) -> [(range: NSRange, text: String)] {
        let value = text as NSString
        guard value.length > 0 else { return [] }
        var result: [(range: NSRange, text: String)] = []
        var location = 0
        while location < value.length {
            let range = value.paragraphRange(for: NSRange(location: location, length: 0))
            let paragraph = normalized(value.substring(with: range))
            if !paragraph.isEmpty {
                result.append((range, paragraph))
            }
            let next = NSMaxRange(range)
            guard next > location else { break }
            location = next
        }
        return result
    }

    private func normalized(_ value: String) -> String {
        value
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
