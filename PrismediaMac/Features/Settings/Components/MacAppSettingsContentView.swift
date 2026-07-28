#if os(macOS)
    import SwiftUI

    struct MacAppSettingsContentView: View {
        @Binding var showsThumbnailText: Bool

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
                    sectionHeading
                    cardPresentationSetting
                }
                .frame(maxWidth: 760, alignment: .leading)
                .padding(PrismediaSpacing.section)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }

        private var sectionHeading: some View {
            HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
                Image(systemName: "rectangle.grid.2x2")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(PrismediaColor.materialSpectrumRed)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                    Text("Entity Grids")
                        .font(.title2.bold())
                    Text("Choose how artwork and metadata are presented throughout your libraries.")
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
            }
        }

        private var cardPresentationSetting: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                LabeledContent {
                    Toggle("Show Text", isOn: $showsThumbnailText)
                        .labelsHidden()
                } label: {
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                        Text("Show Text Below Thumbnails")
                            .font(.headline)
                        Text("Applied to browse, search, and collection grids.")
                            .font(.subheadline)
                            .foregroundStyle(PrismediaColor.textSecondary)
                    }
                }

                Divider()

                Label {
                    Text("Shows each entity’s title, subtitle, and metadata below its artwork.")
                    .font(.callout)
                    .foregroundStyle(PrismediaColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(PrismediaColor.materialSpectrumCyan)
                }
            }
            .padding(PrismediaSpacing.extraExtraLarge)
            .prismediaPanel()
        }
    }

    #if DEBUG
        #Preview("Mac App Settings") {
            @Previewable @State var showsThumbnailText = true

            NavigationStack {
                MacAppSettingsContentView(showsThumbnailText: $showsThumbnailText)
                    .navigationTitle("App Settings")
            }
            .frame(width: 900, height: 620)
            .preferredColorScheme(.dark)
        }
    #endif
#endif
