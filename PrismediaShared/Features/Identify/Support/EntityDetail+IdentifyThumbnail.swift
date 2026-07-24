import Foundation

#if os(iOS) || os(macOS)
    extension EntityDetail {
        var identifyThumbnail: EntityThumbnail {
            let images: EntityImagesCapability? = capability()
            let flags: EntityFlagsCapability? = capability()
            let rating: EntityRatingCapability? = capability()
            let description: EntityDescriptionCapability? = capability()

            return EntityThumbnail(
                id: id,
                kind: kind,
                title: title,
                summary: description?.value,
                parentEntityID: parentEntityID,
                sortOrder: sortOrder,
                coverURL: images?.coverURL,
                coverThumbURL: images?.thumbnailURL,
                coverThumb2xURL: images?.thumbnail2xURL,
                rating: rating?.value,
                isFavorite: flags?.isFavorite ?? false,
                isNsfw: flags?.isNsfw ?? false,
                isOrganized: flags?.isOrganized ?? false,
                isWanted: flags?.isWanted ?? false,
                hasSourceMedia: hasSourceMedia
            )
        }
    }
#endif
