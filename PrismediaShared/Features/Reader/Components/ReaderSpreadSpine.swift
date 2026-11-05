import SwiftUI

/// The shadow in the gutter of an open book, drawn down the middle of a two-page spread
/// so the pages read as two. Folded like a book, the shading parts around the fold.
struct ReaderSpreadSpine: View {
    /// Width of the fold the spread straddles; zero on a flat display.
    var foldWidth: CGFloat = 0
    /// Whether the pages are dark, so the gutter lightens instead of darkening.
    var onDarkPages = false

    private static let shadeWidth: CGFloat = 36

    var body: some View {
        let shade = onDarkPages ? Color.white : Color.black
        let peak = shade.opacity(onDarkPages ? 0.08 : 0.14)
        HStack(spacing: foldWidth) {
            LinearGradient(
                colors: [shade.opacity(0), peak],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: Self.shadeWidth)
            LinearGradient(
                colors: [peak, shade.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: Self.shadeWidth)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#if DEBUG
    #Preview("Reader Spread Spine") {
        ZStack {
            Color(red: 247 / 255, green: 245 / 255, blue: 238 / 255)
            ReaderSpreadSpine()
        }
        .ignoresSafeArea()
    }

    #Preview("Reader Spread Spine · Folded, dark") {
        ZStack {
            Color(red: 18 / 255, green: 18 / 255, blue: 18 / 255)
            ReaderSpreadSpine(foldWidth: 24, onDarkPages: true)
        }
        .ignoresSafeArea()
    }
#endif
