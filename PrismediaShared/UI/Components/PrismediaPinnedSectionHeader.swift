import SwiftUI

/// A content-layer header for pinned list sections. Its opaque semantic fill
/// keeps rows from bleeding through while following system appearance and
/// increased-contrast color variants without turning content into glass.
public struct PrismediaPinnedSectionHeader: View {
    private let title: String

    public init(title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title)
            .font(.headline.bold())
            .foregroundStyle(PrismediaColor.textPrimary)
            .padding(.vertical, PrismediaSpacing.extraSmall)
            .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
            .background(PrismediaColor.groupedContentBackground)
            .overlay(alignment: .bottom) {
                Divider()
            }
            .accessibilityAddTraits(.isHeader)
    }
}

#if DEBUG
    #Preview("Pinned Section Header · Dark") {
        PrismediaPinnedSectionHeader(title: "A")
            .padding(.horizontal, PrismediaSpacing.large)
            .background(PrismediaBackdrop())
            .preferredColorScheme(.dark)
    }

    #Preview("Pinned Section Header · Accessibility Type") {
        PrismediaPinnedSectionHeader(title: "Recently Added")
            .padding(.horizontal, PrismediaSpacing.large)
            .background(PrismediaBackdrop())
            .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
