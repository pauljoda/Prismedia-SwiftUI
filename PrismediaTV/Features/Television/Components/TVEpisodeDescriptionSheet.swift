import SwiftUI

#if os(tvOS)
    struct TVEpisodeDescriptionSheet: View {
        @Environment(\.dismiss) private var dismiss
        let title: String
        let text: String

        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                        Text(title)
                            .font(PrismediaTypography.sectionTitle)
                        Text(text)
                            .font(PrismediaTypography.body)
                            .lineSpacing(PrismediaSpacing.small)
                    }
                    .foregroundStyle(PrismediaColor.textPrimary)
                    .frame(maxWidth: PrismediaLayout.readableContentWidth, alignment: .leading)
                    .padding(.horizontal, PrismediaLayout.televisionContentInset)
                    .padding(.vertical, PrismediaSpacing.section)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .prismediaScreenBackground()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
#endif

#if os(tvOS) && DEBUG
    #Preview("TV Episode Description Sheet · Long Copy") {
        PreviewShell {
            TVEpisodeDescriptionSheet(
                title: "The Signal",
                text:
                    "The crew follows an unexpected signal into a quiet corner of space. The full description remains available without expanding the hero copy beyond its readable width."
            )
        }
    }
#endif
