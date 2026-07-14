import SwiftUI

#if os(tvOS)
    struct TVEpisodeDescriptionView: View {
        @State private var collapsedHeight: CGFloat = 0
        @State private var fullHeight: CGFloat = 0
        @State private var measuredWidth: CGFloat = 0
        @State private var showsFullDescription = false

        let title: String
        let text: String

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                Text(text)
                    .font(.system(size: 24))
                    .foregroundStyle(PrismediaColor.onMedia.opacity(0.88))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .onGeometryChange(for: CGSize.self) { proxy in
                        proxy.size
                    } action: { size in
                        if measuredWidth != size.width { measuredWidth = size.width }
                        if collapsedHeight != size.height { collapsedHeight = size.height }
                    }

                if measuredWidth > 0 {
                    Text(text)
                        .font(.system(size: 24))
                        .frame(width: measuredWidth, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden()
                        .accessibilityHidden(true)
                        .onGeometryChange(for: CGFloat.self) { proxy in
                            proxy.size.height
                        } action: { height in
                            if fullHeight != height { fullHeight = height }
                        }
                        .frame(height: 0)
                }

                if isTruncated {
                    Button("More") { showsFullDescription = true }
                        .buttonStyle(.glass)
                        .controlSize(.small)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(PrismediaColor.onMedia)
                        .accessibilityHint("Shows the full episode description")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .sheet(isPresented: $showsFullDescription) {
                TVEpisodeDescriptionSheet(title: title, text: text)
            }
            .onChange(of: text) {
                collapsedHeight = 0
                fullHeight = 0
                measuredWidth = 0
                showsFullDescription = false
            }
        }

        private var isTruncated: Bool {
            (collapsedHeight > 0 && fullHeight > collapsedHeight + 1)
                || TVEpisodeDescriptionPresentation.likelyRequiresDisclosure(text)
        }
    }
#endif

#if os(tvOS) && DEBUG
    #Preview("TV Episode Description · Truncated") {
        PreviewShell {
            TVEpisodeDescriptionView(
                title: "A Long Episode",
                text: String(
                    repeating: "A detailed episode description with enough copy to require progressive disclosure. ",
                    count: 8)
            )
            .frame(width: 600)
        }
    }

    #Preview("TV Episode Description · Short") {
        PreviewShell {
            TVEpisodeDescriptionView(
                title: "A Short Episode",
                text: "A concise episode description."
            )
            .frame(width: 600)
        }
    }
#endif
