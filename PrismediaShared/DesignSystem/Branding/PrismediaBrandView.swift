import SwiftUI

/// Prismedia's in-app prism mark, presented as content rather than interface
/// chrome. Screens decide its size; the asset keeps its artwork.
public struct PrismediaBrandView: View {
    private let markSize: CGFloat
    private let isDecorative: Bool
    private let usesNsfwMark: Bool

    public init(
        markSize: CGFloat = PrismediaLayout.brandMark,
        isDecorative: Bool = false,
        usesNsfwMark: Bool = false
    ) {
        self.markSize = markSize
        self.isDecorative = isDecorative
        self.usesNsfwMark = usesNsfwMark
    }

    @ViewBuilder
    public var body: some View {
        if usesNsfwMark {
            Image("PrismediaPrismNsfw", bundle: .prismediaResources)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: markSize, height: markSize)
                .accessibilityLabel("Prismedia, NSFW content visible")
                .accessibilityHidden(isDecorative)
                .accessibilityIdentifier("auth.brand.logo.nsfw")
        } else {
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

    #Preview("Brand Mark · NSFW") {
        ZStack {
            PrismediaBackdrop()
            PrismediaBrandView(usesNsfwMark: true)
        }
        .preferredColorScheme(.dark)
    }
#endif
