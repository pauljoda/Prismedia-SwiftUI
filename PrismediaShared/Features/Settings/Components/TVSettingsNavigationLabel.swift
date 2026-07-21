import SwiftUI

#if os(tvOS)
    struct TVSettingsNavigationLabel: View {
        let title: String
        let description: String
        let systemImageName: String

        var body: some View {
            HStack(alignment: .center, spacing: PrismediaSpacing.extraLarge) {
                Image(systemName: systemImageName)
                    .font(.callout.weight(.semibold))
                    .frame(width: 28, height: 28, alignment: .center)

                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                    Text(title)
                        .font(.headline)

                    Text(description)
                        .font(.callout)
                        .foregroundStyle(PrismediaColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
            }
            .padding(.vertical, PrismediaSpacing.small)
            .padding(.horizontal, PrismediaSpacing.small)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
    }

    #if DEBUG
        #Preview("TV Settings Navigation Label") {
            TVSettingsNavigationLabel(
                title: "Player",
                description: "Choose how Prismedia plays movies and episodes on this Apple TV.",
                systemImageName: "play.rectangle"
            )
            .padding(60)
            .prismediaScreenBackground()
        }
    #endif
#endif
