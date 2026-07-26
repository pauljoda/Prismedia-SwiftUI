#if os(macOS)
    import SwiftUI

    struct MacAppSettingsContentView: View {
        @Binding var cardStyle: EntityGridCardStyle

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
                    Picker("Card Presentation", selection: $cardStyle) {
                        ForEach(EntityGridCardStyle.allCases) { option in
                            Label(option.label, systemImage: option.systemImage)
                                .tag(option)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 230)
                } label: {
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                        Text("Card Presentation")
                            .font(.headline)
                        Text("Applied to browse, search, and collection grids.")
                            .font(.subheadline)
                            .foregroundStyle(PrismediaColor.textSecondary)
                    }
                }

                Divider()

                Label {
                    Text(
                        "Artwork Fade extends each thumbnail behind its details. Text Below Artwork uses a simpler Apple-style layout. None shows only the artwork."
                    )
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
            @Previewable @State var cardStyle = EntityGridCardStyle.detailsBelow

            NavigationStack {
                MacAppSettingsContentView(cardStyle: $cardStyle)
                    .navigationTitle("App Settings")
            }
            .frame(width: 900, height: 620)
            .preferredColorScheme(.dark)
        }
    #endif
#endif
