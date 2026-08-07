import SwiftUI

/// Applies the definition-owned background and padding around original Entity artwork.
public struct EntityArtworkSurfaceView<Content: View>: View {
    private let surface: EntityArtworkSurface
    private let content: Content

    public init(
        surface: EntityArtworkSurface,
        @ViewBuilder content: () -> Content
    ) {
        self.surface = surface
        self.content = content()
    }

    public var body: some View {
        ZStack {
            if surface == .brandPlate {
                brandPlate
            }

            content
                .padding(surface == .brandPlate ? PrismediaSpacing.medium : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var brandPlate: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 232 / 255, green: 221 / 255, blue: 190 / 255).opacity(0.92),
                    Color(red: 150 / 255, green: 134 / 255, blue: 96 / 255).opacity(0.72),
                    PrismediaColor.groupedContentBackground.opacity(0.94),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [PrismediaColor.onMedia.opacity(0.32), .clear],
                center: UnitPoint(x: 0.34, y: 0.24),
                startRadius: 0,
                endRadius: 180
            )
        }
    }
}
