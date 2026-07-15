import Foundation

final class EPUBPackageXMLDelegate: NSObject, XMLParserDelegate {
    private(set) var title: String?
    private(set) var manifest: [String: EPUBManifestItem] = [:]
    private(set) var spine: [String] = []
    private(set) var tableOfContentsID: String?
    private var collectingTitle = false
    private var titleText = ""

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        switch localName(elementName) {
        case "title":
            collectingTitle = true
            titleText = ""
        case "item":
            guard let id = attributeDict["id"],
                let href = attributeDict["href"],
                let mediaType = attributeDict["media-type"]
            else { return }
            manifest[id] = EPUBManifestItem(
                id: id,
                href: href,
                mediaType: mediaType,
                properties: Set(
                    (attributeDict["properties"] ?? "")
                        .split(whereSeparator: \.isWhitespace)
                        .map(String.init)
                )
            )
        case "itemref":
            if let idref = attributeDict["idref"] { spine.append(idref) }
        case "spine":
            tableOfContentsID = attributeDict["toc"]
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard collectingTitle else { return }
        titleText += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        guard localName(elementName) == "title" else { return }
        collectingTitle = false
        let value = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !value.isEmpty { title = value }
    }

    private func localName(_ name: String) -> String {
        name.split(separator: ":").last.map { $0.lowercased() } ?? name.lowercased()
    }
}
