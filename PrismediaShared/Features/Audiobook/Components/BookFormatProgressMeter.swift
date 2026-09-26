import SwiftUI

/// One format's own progress on a Book that keeps reading and listening Separate: a titled meter
/// with its whole percent, so the two formats never read as one number.
struct BookFormatProgressMeter: View {
    let title: LocalizedStringKey
    let systemImage: String
    let percent: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PrismediaColor.textPrimary)
                Spacer(minLength: PrismediaSpacing.large)
                Text("\(percent)%")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(PrismediaColor.textPrimary)
            }
            ProgressView(value: Double(min(max(percent, 0), 100)), total: 100)
                .tint(tint)
                .frame(height: 4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue("\(percent) percent")
    }
}

#if DEBUG
    #Preview("Book Format Progress Meters") {
        PreviewShell {
            VStack(spacing: PrismediaSpacing.large) {
                BookFormatProgressMeter(
                    title: "Reading",
                    systemImage: "book.fill",
                    percent: 42,
                    tint: PrismediaColor.accent
                )
                BookFormatProgressMeter(
                    title: "Listening",
                    systemImage: "headphones",
                    percent: 12,
                    tint: PrismediaColor.accent.opacity(PrismediaOpacity.secondaryMeter)
                )
            }
            .padding(PrismediaSpacing.extraLarge)
            .prismediaPanel()
            .padding(PrismediaSpacing.extraLarge)
        }
    }
#endif
