import SwiftUI

/// Prismedia's in-app prism mark, presented as content rather than interface
/// chrome. Screens decide its size; the asset keeps its artwork.
public struct PrismediaBrandView: View {
    private let markSize: CGFloat
    private let isDecorative: Bool

    public init(
        markSize: CGFloat = PrismediaLayout.brandMark,
        isDecorative: Bool = false
    ) {
        self.markSize = markSize
        self.isDecorative = isDecorative
    }

    public var body: some View {
        Image("PrismediaPrismColor", bundle: .prismediaResources)
            .resizable()
            .renderingMode(.original)
            .scaledToFit()
            .frame(width: markSize, height: markSize)
            .accessibilityLabel("Prismedia")
            .accessibilityHidden(isDecorative)
            .accessibilityIdentifier("auth.brand.logo")
    }
}

#if DEBUG
    #Preview("Brand Mark") {
        ZStack {
            PrismediaBackdrop()
            PrismediaBrandView()
        }
        .preferredColorScheme(.dark)
    }

    #Preview("Brand Mark · Compact") {
        ZStack {
            PrismediaBackdrop()
            PrismediaBrandView(markSize: PrismediaLayout.compactBrandMark)
        }
        .frame(width: 220, height: 180)
        .preferredColorScheme(.dark)
    }
#endif
