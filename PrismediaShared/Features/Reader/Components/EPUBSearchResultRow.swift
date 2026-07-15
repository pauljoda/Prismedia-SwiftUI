#if os(iOS) && canImport(ReadiumNavigator)
    import SwiftUI

    struct EPUBSearchResultRow: View {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

        let result: EPUBSearchResult

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.small) {
                    Text(result.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    Spacer(minLength: PrismediaSpacing.small)

                    if let locationLabel = result.locationLabel {
                        Text(locationLabel)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                Text(attributedExcerpt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            .accessibilityElement(children: .combine)
        }

        private var attributedExcerpt: AttributedString {
            var excerpt = AttributedString(result.before ?? "")
            var match = AttributedString(result.highlight ?? "")
            match.font = .caption.bold()
            match.foregroundColor = artworkPrimaryAccent
            excerpt.append(match)
            excerpt.append(AttributedString(result.after ?? ""))
            return excerpt
        }
    }

    #if DEBUG
        #Preview("EPUB Search Result") {
            EPUBSearchResultRow(
                result: EPUBSearchResult(
                    id: "preview-result",
                    title: "Appendix A",
                    before: "The index points toward the ",
                    highlight: "signal",
                    after: " recorded beyond the harbor.",
                    chapterPage: 10,
                    chapterPageCount: 51,
                    location: "appendix-a"
                )
            )
            .padding()
        }
    #endif
#endif
