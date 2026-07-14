import Foundation
import XCTest
import zlib

@testable import PrismediaCore

final class EPUBPublicationLoaderTests: XCTestCase {
    func testLoadsNestedEPUB3NavigationAsTableOfContents() throws {
        let fixture = try makeArchive(
            [
                "META-INF/container.xml": """
                <?xml version="1.0"?>
                <container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
                  <rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles>
                </container>
                """,
                "OEBPS/content.opf": """
                <?xml version="1.0"?>
                <package xmlns="http://www.idpf.org/2007/opf" version="3.0">
                  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>Navigation Fixture</dc:title></metadata>
                  <manifest>
                    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
                    <item id="one" href="Text/one.xhtml" media-type="application/xhtml+xml"/>
                    <item id="two" href="Text/two.xhtml" media-type="application/xhtml+xml"/>
                  </manifest>
                  <spine><itemref idref="one"/><itemref idref="two"/></spine>
                </package>
                """,
                "OEBPS/nav.xhtml": """
                <?xml version="1.0"?>
                <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
                  <body><nav epub:type="toc"><ol>
                    <li><a href="Text/one.xhtml#start">Arrival</a>
                      <ol><li><a href="Text/one.xhtml#signal">The Signal</a></li></ol>
                    </li>
                    <li><a href="Text/two.xhtml">Departure</a></li>
                  </ol></nav></body>
                </html>
                """,
                "OEBPS/Text/one.xhtml":
                    "<html><body><h1 id=\"start\">Arrival</h1><h2 id=\"signal\">The Signal</h2></body></html>",
                "OEBPS/Text/two.xhtml": "<html><body>Departure</body></html>",
            ]
        )
        let destination = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: destination) }

        let publication = try EPUBPublicationLoader().load(
            data: fixture,
            fallbackTitle: "Fallback",
            destination: destination
        )

        XCTAssertEqual(publication.tableOfContents.map(\.title), ["Arrival", "Departure"])
        XCTAssertEqual(publication.tableOfContents[0].location, "Text/one.xhtml#start")
        XCTAssertEqual(publication.tableOfContents[0].children.map(\.title), ["The Signal"])
        XCTAssertEqual(publication.tableOfContents[0].children[0].location, "Text/one.xhtml#signal")
    }

    func testLoadsContainerManifestAndSpineIntoLocalSanitizedChapters() throws {
        let fixture = try makeArchive(
            [
                "META-INF/container.xml": """
                <?xml version="1.0"?>
                <container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
                  <rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles>
                </container>
                """,
                "OEBPS/content.opf": """
                <?xml version="1.0"?>
                <package xmlns="http://www.idpf.org/2007/opf" version="3.0">
                  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>Fixture Book</dc:title></metadata>
                  <manifest>
                    <item id="chapter-one" href="Text/one.xhtml" media-type="application/xhtml+xml"/>
                    <item id="chapter-two" href="Text/two.xhtml" media-type="application/xhtml+xml"/>
                  </manifest>
                  <spine><itemref idref="chapter-two"/><itemref idref="chapter-one"/></spine>
                </package>
                """,
                "OEBPS/Text/one.xhtml": "<html><head><script>alert('no')</script></head><body>One</body></html>",
                "OEBPS/Text/two.xhtml": "<html><body>Two</body></html>",
            ], compression: 8)
        let destination = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: destination) }

        let publication = try EPUBPublicationLoader().load(
            data: fixture,
            fallbackTitle: "Fallback",
            destination: destination
        )

        XCTAssertEqual(publication.title, "Fixture Book")
        XCTAssertEqual(publication.chapters.map(\.location), ["Text/two.xhtml", "Text/one.xhtml"])
        XCTAssertTrue(publication.chapters.allSatisfy { $0.fileURL.isFileURL })
        let sanitized = try String(contentsOf: publication.chapters[1].fileURL, encoding: .utf8)
        XCTAssertFalse(sanitized.localizedCaseInsensitiveContains("<script"))
        XCTAssertTrue(sanitized.contains("Content-Security-Policy"))
    }

    func testRejectsArchiveTraversalBeforeWritingFiles() throws {
        let fixture = try makeArchive(["../escape.xhtml": "nope"])
        let destination = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: destination) }

        XCTAssertThrowsError(
            try EPUBPublicationLoader().load(
                data: fixture,
                fallbackTitle: "Unsafe",
                destination: destination
            )
        ) { error in
            XCTAssertEqual(error as? EPUBReaderError, .unsafeArchivePath("../escape.xhtml"))
        }
    }

    private func makeArchive(_ entries: [String: String], compression: UInt16 = 0) throws -> Data {
        var localData = Data()
        var centralData = Data()
        var count: UInt16 = 0

        for (path, contents) in entries.sorted(by: { $0.key < $1.key }) {
            let name = Data(path.utf8)
            let payload = Data(contents.utf8)
            let encoded = compression == 8 ? try rawDeflate(payload) : payload
            let offset = UInt32(localData.count)
            localData.appendLittleEndian(UInt32(0x0403_4B50))
            localData.appendLittleEndian(UInt16(20))
            localData.appendLittleEndian(UInt16(0))
            localData.appendLittleEndian(compression)
            localData.appendLittleEndian(UInt16(0))
            localData.appendLittleEndian(UInt16(0))
            localData.appendLittleEndian(UInt32(0))
            localData.appendLittleEndian(UInt32(encoded.count))
            localData.appendLittleEndian(UInt32(payload.count))
            localData.appendLittleEndian(UInt16(name.count))
            localData.appendLittleEndian(UInt16(0))
            localData.append(name)
            localData.append(encoded)

            centralData.appendLittleEndian(UInt32(0x0201_4B50))
            centralData.appendLittleEndian(UInt16(20))
            centralData.appendLittleEndian(UInt16(20))
            centralData.appendLittleEndian(UInt16(0))
            centralData.appendLittleEndian(compression)
            centralData.appendLittleEndian(UInt16(0))
            centralData.appendLittleEndian(UInt16(0))
            centralData.appendLittleEndian(UInt32(0))
            centralData.appendLittleEndian(UInt32(encoded.count))
            centralData.appendLittleEndian(UInt32(payload.count))
            centralData.appendLittleEndian(UInt16(name.count))
            centralData.appendLittleEndian(UInt16(0))
            centralData.appendLittleEndian(UInt16(0))
            centralData.appendLittleEndian(UInt16(0))
            centralData.appendLittleEndian(UInt16(0))
            centralData.appendLittleEndian(UInt32(0))
            centralData.appendLittleEndian(offset)
            centralData.append(name)
            count += 1
        }

        let centralOffset = UInt32(localData.count)
        localData.append(centralData)
        localData.appendLittleEndian(UInt32(0x0605_4B50))
        localData.appendLittleEndian(UInt16(0))
        localData.appendLittleEndian(UInt16(0))
        localData.appendLittleEndian(count)
        localData.appendLittleEndian(count)
        localData.appendLittleEndian(UInt32(centralData.count))
        localData.appendLittleEndian(centralOffset)
        localData.appendLittleEndian(UInt16(0))
        return localData
    }

    private func rawDeflate(_ data: Data) throws -> Data {
        var stream = z_stream()
        guard
            deflateInit2_(
                &stream,
                Z_DEFAULT_COMPRESSION,
                Z_DEFLATED,
                -MAX_WBITS,
                8,
                Z_DEFAULT_STRATEGY,
                ZLIB_VERSION,
                Int32(MemoryLayout<z_stream>.size)
            ) == Z_OK
        else {
            throw EPUBReaderError.invalidArchive
        }
        defer { deflateEnd(&stream) }
        var output = Data(count: Int(deflateBound(&stream, uLong(data.count))))
        let status = data.withUnsafeBytes { source in
            output.withUnsafeMutableBytes { destination in
                stream.next_in = UnsafeMutablePointer(mutating: source.bindMemory(to: Bytef.self).baseAddress)
                stream.avail_in = uInt(source.count)
                stream.next_out = destination.bindMemory(to: Bytef.self).baseAddress
                stream.avail_out = uInt(destination.count)
                return zlib.deflate(&stream, Z_FINISH)
            }
        }
        guard status == Z_STREAM_END else { throw EPUBReaderError.invalidArchive }
        output.removeSubrange(Int(stream.total_out)..<output.count)
        return output
    }
}

extension Data {
    fileprivate mutating func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
        var value = value.littleEndian
        Swift.withUnsafeBytes(of: &value) { append(contentsOf: $0) }
    }
}
