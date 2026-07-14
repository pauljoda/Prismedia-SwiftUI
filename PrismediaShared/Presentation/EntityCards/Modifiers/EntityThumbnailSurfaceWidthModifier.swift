import SwiftUI

struct EntityThumbnailSurfaceWidthModifier: ViewModifier {
    let preferredWidth: CGFloat?

    func body(content: Content) -> some View {
        if let preferredWidth {
            content.frame(width: preferredWidth, alignment: .topLeading)
        } else {
            content.frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

#if DEBUG
    #Preview("Thumbnail Surface Width · Preferred") {
        Text("Fixed media surface")
            .frame(height: 96)
            .modifier(EntityThumbnailSurfaceWidthModifier(preferredWidth: 220))
            .background(PrismediaColor.elevatedContentBackground)
            .padding()
            .background(PrismediaColor.background)
    }
#endif
