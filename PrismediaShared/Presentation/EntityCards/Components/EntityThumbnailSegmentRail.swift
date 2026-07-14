import SwiftUI

struct EntityThumbnailSegmentRail: View {
    let options: [EntityThumbnailPreviewOption]
    let activeIndex: Int?

    var body: some View {
        HStack(spacing: PrismediaSpacing.extraSmall) {
            ForEach(options) { option in
                Capsule()
                    .fill(
                        option.id == activeOptionID
                            ? PrismediaColor.onMedia
                            : PrismediaColor.onMedia.opacity(0.42)
                    )
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 3)
        .padding(PrismediaSpacing.extraSmall)
        .background(PrismediaColor.background.opacity(0.38), in: Capsule())
        .accessibilityHidden(true)
    }

    private var activeOptionID: EntityThumbnailPreviewOption.ID? {
        guard let activeIndex, options.indices.contains(activeIndex) else { return nil }
        return options[activeIndex].id
    }
}

#if DEBUG
    #Preview("Segment Rail") {
        EntityThumbnailSegmentRail(
            options: [
                EntityThumbnailPreviewOption(entityID: nil, title: "Pilot", path: "/pilot.jpg"),
                EntityThumbnailPreviewOption(entityID: nil, title: "Middle", path: "/middle.jpg"),
                EntityThumbnailPreviewOption(entityID: nil, title: "Finale", path: "/finale.jpg"),
            ],
            activeIndex: 1
        )
        .frame(width: 240)
        .padding()
        .background(PrismediaColor.groupedContentBackground)
    }
#endif
