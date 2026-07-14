import SwiftUI

#if os(tvOS)
    struct TVAccountView: View {
        let user: UserAccount
        let onSignOut: () -> Void

        @State private var isConfirmingSignOut = false

        var body: some View {
            VStack(spacing: PrismediaSpacing.extraExtraLarge) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 112, weight: .regular))
                    .foregroundStyle(PrismediaColor.accent)
                    .accessibilityHidden(true)

                VStack(spacing: PrismediaSpacing.small) {
                    Text(user.displayName)
                        .font(.largeTitle.bold())
                        .foregroundStyle(PrismediaColor.textPrimary)

                    Text("@\(user.username)")
                        .font(.title3)
                        .foregroundStyle(PrismediaColor.textSecondary)

                    Text(user.role.rawValue.capitalized)
                        .font(.headline)
                        .foregroundStyle(PrismediaColor.textMuted)
                }

                PrismediaButton(
                    "Sign Out",
                    systemImage: "rectangle.portrait.and.arrow.right",
                    variant: .destructive,
                    form: .fill
                ) {
                    isConfirmingSignOut = true
                }
                .frame(width: 360)
                .accessibilityIdentifier("tv.account.sign-out")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .prismediaScreenBackground()
            .alert("Sign Out?", isPresented: $isConfirmingSignOut) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive, action: onSignOut)
            } message: {
                Text("You’ll return to the Prismedia sign-in screen on this Apple TV.")
            }
            .accessibilityIdentifier("tv.account")
        }
    }

    #if DEBUG
        #Preview("TV Account") {
            TVAccountView(user: PrismediaPreviewData.user, onSignOut: {})
        }
    #endif
#endif
