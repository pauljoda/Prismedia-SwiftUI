import SwiftUI

struct EntityDetailStatusChip: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        PrismediaGlassStatusChip(
            title,
            systemImage: systemImage,
            tint: tint
        )
    }
}
#if DEBUG
    #Preview("Status Chip") {
        EntityDetailStatusChip(title: "Favorite", systemImage: "heart.fill", tint: PrismediaColor.accent)
            .padding(PrismediaSpacing.large)
    }
#endif
