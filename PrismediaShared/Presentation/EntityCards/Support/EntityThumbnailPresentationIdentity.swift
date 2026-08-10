import Foundation

/// Produces stable, presentation-only identifiers for thumbnail models that
/// have not been persisted as Prismedia entities yet.
enum EntityThumbnailPresentationIdentity {
    static func id(namespace: String, value: String) -> UUID {
        let bytes = Array("\(namespace):\(value)".utf8)
        let first = hash(bytes, seed: 0xcbf29ce484222325)
        let second = hash(bytes, seed: 0x84222325cbf29ce4)
        let combined = withUnsafeBytes(of: first.bigEndian, Array.init)
            + withUnsafeBytes(of: second.bigEndian, Array.init)

        return UUID(uuid: (
            combined[0], combined[1], combined[2], combined[3],
            combined[4], combined[5], combined[6], combined[7],
            combined[8], combined[9], combined[10], combined[11],
            combined[12], combined[13], combined[14], combined[15]
        ))
    }

    private static func hash(_ bytes: [UInt8], seed: UInt64) -> UInt64 {
        bytes.reduce(seed) { partialResult, byte in
            (partialResult ^ UInt64(byte)) &* 0x100000001b3
        }
    }
}
