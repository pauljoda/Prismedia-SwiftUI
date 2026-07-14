import Foundation

final class EPUBNavigationDocumentDelegate: NSObject, XMLParserDelegate {
    private(set) var entries: [(title: String, href: String, depth: Int)] = []

    private var isInsideTableOfContents = false
    private var listDepth = -1
    private var currentHref: String?
    private var currentTitle = ""

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        let name = localName(elementName)
        if name == "nav" {
            let type = attributeDict.first { key, _ in
                key == "epub:type" || localName(key) == "type"
            }?.value
            isInsideTableOfContents = type?.split(whereSeparator: \.isWhitespace).contains("toc") == true
            return
        }
        guard isInsideTableOfContents else { return }
        if name == "ol" {
            listDepth += 1
        } else if name == "a" {
            currentHref = attributeDict["href"]
            currentTitle = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard currentHref != nil else { return }
        currentTitle += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let name = localName(elementName)
        if name == "a", let href = currentHref {
            let title = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            if !title.isEmpty {
                entries.append((title: title, href: href, depth: max(0, listDepth)))
            }
            currentHref = nil
            currentTitle = ""
        } else if name == "ol", isInsideTableOfContents {
            listDepth -= 1
        } else if name == "nav", isInsideTableOfContents {
            isInsideTableOfContents = false
            listDepth = -1
        }
    }

    private func localName(_ name: String) -> String {
        name.split(separator: ":").last.map { $0.lowercased() } ?? name.lowercased()
    }
}
