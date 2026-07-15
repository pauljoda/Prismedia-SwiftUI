import Foundation

final class EPUBNCXNavigationDelegate: NSObject, XMLParserDelegate {
    private(set) var entries: [(title: String, href: String, depth: Int)] = []

    private var depth = -1
    private var titles: [String] = []
    private var hrefs: [String?] = []
    private var emitted: [Bool] = []
    private var isCollectingTitle = false

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        switch localName(elementName) {
        case "navpoint":
            depth += 1
            titles.append("")
            hrefs.append(nil)
            emitted.append(false)
        case "text" where depth >= 0:
            isCollectingTitle = true
        case "content" where depth >= 0:
            hrefs[depth] = attributeDict["src"]
            emitCurrentEntryIfPossible()
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard isCollectingTitle, depth >= 0 else { return }
        titles[depth] += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        switch localName(elementName) {
        case "text":
            isCollectingTitle = false
        case "navpoint" where depth >= 0:
            emitCurrentEntryIfPossible()
            titles.removeLast()
            hrefs.removeLast()
            emitted.removeLast()
            depth -= 1
        default:
            break
        }
    }

    private func emitCurrentEntryIfPossible() {
        guard depth >= 0, !emitted[depth], let href = hrefs[depth] else { return }
        let title = titles[depth].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !href.isEmpty else { return }
        entries.append((title: title, href: href, depth: depth))
        emitted[depth] = true
    }

    private func localName(_ name: String) -> String {
        name.split(separator: ":").last.map { $0.lowercased() } ?? name.lowercased()
    }
}
