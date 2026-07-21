import SwiftUI

#if os(tvOS)
    struct TVSettingsIdentityPanel: View {
        let title: String
        let description: String

        var body: some View {
            VStack(spacing: PrismediaSpacing.extraExtraLarge) {
                ZStack {
                    RoundedRectangle(cornerRadius: PrismediaRadius.panel, style: .continuous)
                        .fill(PrismediaColor.elevatedContentBackground)

                    PrismediaBrandView(markSize: 180)
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 360)

                VStack(spacing: PrismediaSpacing.medium) {
                    Text(title)
                        .font(.title.bold())
                        .foregroundStyle(PrismediaColor.textPrimary)

                    Text(description)
                        .font(.headline)
                        .foregroundStyle(PrismediaColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .frame(maxWidth: 520)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(PrismediaSpacing.extraExtraLarge)
            .accessibilityElement(children: .combine)
        }
    }

    #if DEBUG
        #Preview("TV Settings Identity") {
            TVSettingsIdentityPanel(
                title: "Settings",
                description: "Choose how Prismedia looks, plays, and connects on this Apple TV."
            )
            .frame(width: 760, height: 900)
            .background { PrismediaBackdrop() }
        }
    #endif
#endif
