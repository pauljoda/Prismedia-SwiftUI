#if DEBUG
    import SwiftUI

    #Preview("Design System · Spectral Dark") {
        let swatches: [(String, Color)] = [
            ("Background", PrismediaColor.background),
            ("Grouped Content", PrismediaColor.groupedContentBackground),
            ("Elevated Content", PrismediaColor.elevatedContentBackground),
            ("Control Fill", PrismediaColor.controlFill),
            ("Strong Control", PrismediaColor.strongControlFill),
            ("Accent", PrismediaColor.accent),
            ("Spectrum Red", PrismediaColor.spectrumRed),
            ("Spectrum Orange", PrismediaColor.spectrumOrange),
            ("Spectrum Yellow", PrismediaColor.spectrumYellow),
            ("Spectrum Green", PrismediaColor.spectrumGreen),
            ("Spectrum Cyan", PrismediaColor.spectrumCyan),
            ("Spectrum Blue", PrismediaColor.spectrumBlue),
            ("Spectrum Violet", PrismediaColor.spectrumViolet),
            ("Spectrum Magenta", PrismediaColor.spectrumMagenta),
        ]

        ZStack {
            PrismediaBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraLarge) {
                    Text("Prismedia Design System")
                        .font(.largeTitle.bold())

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 120))],
                        spacing: PrismediaSpacing.medium
                    ) {
                        ForEach(swatches, id: \.0) { name, color in
                            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                                color
                                    .frame(height: 54)
                                    .clipShape(.rect(cornerRadius: PrismediaRadius.compact))
                                Text(name)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(PrismediaSpacing.extraLarge)
            }
        }
        .tint(PrismediaColor.accent)
        .preferredColorScheme(.dark)
    }

    #Preview("Design System · Accessibility Type") {
        let swatches: [(String, Color)] = [
            ("Background", PrismediaColor.background),
            ("Grouped Content", PrismediaColor.groupedContentBackground),
            ("Elevated Content", PrismediaColor.elevatedContentBackground),
            ("Control Fill", PrismediaColor.controlFill),
            ("Strong Control", PrismediaColor.strongControlFill),
            ("Accent", PrismediaColor.accent),
            ("Spectrum Red", PrismediaColor.spectrumRed),
            ("Spectrum Orange", PrismediaColor.spectrumOrange),
            ("Spectrum Yellow", PrismediaColor.spectrumYellow),
            ("Spectrum Green", PrismediaColor.spectrumGreen),
            ("Spectrum Cyan", PrismediaColor.spectrumCyan),
            ("Spectrum Blue", PrismediaColor.spectrumBlue),
            ("Spectrum Violet", PrismediaColor.spectrumViolet),
            ("Spectrum Magenta", PrismediaColor.spectrumMagenta),
        ]

        ZStack {
            PrismediaBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraLarge) {
                    Text("Prismedia Design System")
                        .font(.largeTitle.bold())

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 120))],
                        spacing: PrismediaSpacing.medium
                    ) {
                        ForEach(swatches, id: \.0) { name, color in
                            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                                color
                                    .frame(height: 54)
                                    .clipShape(.rect(cornerRadius: PrismediaRadius.compact))
                                Text(name)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(PrismediaSpacing.extraLarge)
            }
        }
        .tint(PrismediaColor.accent)
        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
