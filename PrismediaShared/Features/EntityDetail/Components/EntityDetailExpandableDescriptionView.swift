import SwiftUI

struct EntityDetailExpandableDescriptionView: View {
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
    @Environment(\.artworkSecondaryText) private var artworkSecondaryText
    @State private var isExpanded = false
    @State private var collapsedHeight: CGFloat = 0
    @State private var expandedHeight: CGFloat = 0

    let description: String
    let lineLimit: Int

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            descriptionText
                .lineLimit(isExpanded ? nil : lineLimit)
                .background { measurementViews }
                .accessibilityIdentifier("entity-detail.summary")

            if isTruncated || isExpanded {
                Button(isExpanded ? "Show Less" : "More") {
                    isExpanded.toggle()
                }
                .font(.callout.weight(.semibold))
                .foregroundStyle(artworkPrimaryAccent)
                .buttonStyle(.plain)
                .accessibilityHint(
                    isExpanded ? "Collapses the description" : "Shows the full description"
                )
                .accessibilityIdentifier("entity-detail.summary-disclosure")
            }
        }
    }

    private var descriptionText: some View {
        Text(description)
            .font(PrismediaTypography.body)
            .foregroundStyle(artworkSecondaryText)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
            .prismediaTextSelection()
    }

    private var measurementViews: some View {
        ZStack {
            descriptionText
                .lineLimit(lineLimit)
                .hidden()
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    collapsedHeight = height
                }

            descriptionText
                .hidden()
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    expandedHeight = height
                }
        }
        .accessibilityHidden(true)
    }

    private var isTruncated: Bool {
        expandedHeight > collapsedHeight + 1
    }
}

#if DEBUG
    #Preview("Entity Description · Collapsed") {
        EntityDetailExpandableDescriptionView(
            description:
                "A long description should remain easy to scan while still making the complete synopsis available on demand. This preview deliberately continues across enough words to exceed the compact summary and reveal the More control at the end of the text.",
            lineLimit: 3
        )
        .padding()
        .frame(width: 360)
        .preferredColorScheme(.dark)
    }
#endif
