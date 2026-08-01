import Foundation

extension EntityDetail {
    func mergingUserMetadata(from response: EntityDetail) -> EntityDetail {
        var mergedCapabilities = capabilities
        for capability in response.capabilities where capability.isUserMetadata {
            if let index = mergedCapabilities.firstIndex(where: { $0.hasSameUserMetadataKind(as: capability) }) {
                mergedCapabilities[index] = capability
            } else {
                mergedCapabilities.append(capability)
            }
        }

        return EntityDetail(
            id: id,
            kind: kind,
            title: title,
            parentEntityID: parentEntityID,
            sortOrder: sortOrder,
            hasSourceMedia: hasSourceMedia,
            capabilities: mergedCapabilities,
            childrenByKind: childrenByKind,
            relationships: relationships
        )
    }
}

extension EntityCapability {
    fileprivate var isUserMetadata: Bool {
        kind == .flags || kind == .rating
    }

    fileprivate func hasSameUserMetadataKind(as other: EntityCapability) -> Bool {
        kind == other.kind
    }
}
