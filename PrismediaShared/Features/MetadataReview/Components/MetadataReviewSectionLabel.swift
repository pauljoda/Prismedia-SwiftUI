import SwiftUI

#if os(iOS) || os(macOS)
    /// Gives review groups a consistent title and a separate, readable selection summary.
    struct MetadataReviewSectionLabel: View {
        let title: String
        let systemImage: String
        let summary: String

        var body: some View {
            Label {
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                    Text(title)
                        .font(.headline)
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } icon: {
                Image(systemName: systemImage)
                    .font(.headline)
            }
        }
    }

    #if DEBUG
        #Preview("Review Section · Large Text") {
            PreviewShell {
                DisclosureGroup {
                    Text("Review the proposed values.")
                } label: {
                    MetadataReviewSectionLabel(
                        title: "Metadata",
                        systemImage: "list.bullet.rectangle",
                        summary: "4 of 5 selected"
                    )
                }
                .padding()
                .environment(\.dynamicTypeSize, .accessibility3)
            }
        }
    #endif
#endif
