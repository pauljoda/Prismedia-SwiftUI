import Foundation

final class EPUBContainerXMLDelegate: NSObject, XMLParserDelegate {
    private(set) var packagePath: String?

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        guard elementName.split(separator: ":").last == "rootfile", packagePath == nil else { return }
        packagePath = attributeDict["full-path"]
    }
}
