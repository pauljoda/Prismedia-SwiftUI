import Foundation
import zlib

struct EPUBZipArchiveReader: Sendable {
    func entries(in data: Data) throws -> [String: Data] {
        guard let directoryOffset = endOfCentralDirectory(in: data) else {
            throw EPUBReaderError.invalidArchive
        }
        let entryCount: UInt16 = try value(in: data, at: directoryOffset + 10)
        let centralOffset: UInt32 = try value(in: data, at: directoryOffset + 16)
        var cursor = Int(centralOffset)
        var entries: [String: Data] = [:]
        var totalUncompressedSize = 0

        for _ in 0..<entryCount {
            let signature: UInt32 = try value(in: data, at: cursor)
            guard signature == 0x0201_4B50 else { throw EPUBReaderError.invalidArchive }
            let flags: UInt16 = try value(in: data, at: cursor + 8)
            guard flags & 0x1 == 0 else { throw EPUBReaderError.unsupportedDRM }
            let compression: UInt16 = try value(in: data, at: cursor + 10)
            let compressedSize: UInt32 = try value(in: data, at: cursor + 20)
            let uncompressedSize: UInt32 = try value(in: data, at: cursor + 24)
            guard uncompressedSize <= 134_217_728 else { throw EPUBReaderError.archiveTooLarge }
            totalUncompressedSize += Int(uncompressedSize)
            guard totalUncompressedSize <= 1_073_741_824 else { throw EPUBReaderError.archiveTooLarge }
            let nameLength: UInt16 = try value(in: data, at: cursor + 28)
            let extraLength: UInt16 = try value(in: data, at: cursor + 30)
            let commentLength: UInt16 = try value(in: data, at: cursor + 32)
            let localOffset: UInt32 = try value(in: data, at: cursor + 42)
            let nameData = try slice(data, at: cursor + 46, count: Int(nameLength))
            guard let rawName = String(data: nameData, encoding: .utf8) else {
                throw EPUBReaderError.invalidArchive
            }
            let name = try safePath(rawName)
            if !name.hasSuffix("/") {
                entries[name] = try payload(
                    in: data,
                    localOffset: Int(localOffset),
                    compressedSize: Int(compressedSize),
                    uncompressedSize: Int(uncompressedSize),
                    compression: compression
                )
            }
            cursor += 46 + Int(nameLength) + Int(extraLength) + Int(commentLength)
        }
        return entries
    }

    private func payload(
        in archive: Data,
        localOffset: Int,
        compressedSize: Int,
        uncompressedSize: Int,
        compression: UInt16
    ) throws -> Data {
        let signature: UInt32 = try value(in: archive, at: localOffset)
        guard signature == 0x0403_4B50 else { throw EPUBReaderError.invalidArchive }
        let nameLength: UInt16 = try value(in: archive, at: localOffset + 26)
        let extraLength: UInt16 = try value(in: archive, at: localOffset + 28)
        let start = localOffset + 30 + Int(nameLength) + Int(extraLength)
        let compressed = try slice(archive, at: start, count: compressedSize)
        switch compression {
        case 0:
            guard compressed.count == uncompressedSize else { throw EPUBReaderError.invalidArchive }
            return compressed
        case 8:
            return try inflate(compressed, expectedSize: uncompressedSize)
        default:
            throw EPUBReaderError.unsupportedCompression(compression)
        }
    }

    private func inflate(_ data: Data, expectedSize: Int) throws -> Data {
        var stream = z_stream()
        let initialized = inflateInit2_(
            &stream,
            -MAX_WBITS,
            ZLIB_VERSION,
            Int32(MemoryLayout<z_stream>.size)
        )
        guard initialized == Z_OK else { throw EPUBReaderError.invalidArchive }
        defer { inflateEnd(&stream) }

        var output = Data(count: expectedSize)
        let status = data.withUnsafeBytes { source in
            output.withUnsafeMutableBytes { destination in
                stream.next_in = UnsafeMutablePointer(mutating: source.bindMemory(to: Bytef.self).baseAddress)
                stream.avail_in = uInt(source.count)
                stream.next_out = destination.bindMemory(to: Bytef.self).baseAddress
                stream.avail_out = uInt(destination.count)
                return zlib.inflate(&stream, Z_FINISH)
            }
        }
        guard status == Z_STREAM_END, Int(stream.total_out) == expectedSize else {
            throw EPUBReaderError.invalidArchive
        }
        return output
    }

    private func endOfCentralDirectory(in data: Data) -> Int? {
        guard data.count >= 22 else { return nil }
        let lowerBound = max(0, data.count - 65_557)
        for offset in stride(from: data.count - 22, through: lowerBound, by: -1) {
            let signature: UInt32? = try? value(in: data, at: offset)
            if signature == 0x0605_4B50 { return offset }
        }
        return nil
    }

    private func safePath(_ path: String) throws -> String {
        let normalized = path.replacingOccurrences(of: "\\", with: "/")
        let parts = normalized.split(separator: "/", omittingEmptySubsequences: false)
        guard !normalized.hasPrefix("/"), !parts.contains(".."), !normalized.contains("\0") else {
            throw EPUBReaderError.unsafeArchivePath(path)
        }
        return normalized
    }

    private func slice(_ data: Data, at offset: Int, count: Int) throws -> Data {
        guard offset >= 0, count >= 0, offset <= data.count - count else {
            throw EPUBReaderError.invalidArchive
        }
        return data.subdata(in: offset..<(offset + count))
    }

    private func value<T: FixedWidthInteger>(in data: Data, at offset: Int) throws -> T {
        let bytes = try slice(data, at: offset, count: MemoryLayout<T>.size)
        return bytes.withUnsafeBytes { rawBuffer in
            rawBuffer.loadUnaligned(as: T.self).littleEndian
        }
    }
}
