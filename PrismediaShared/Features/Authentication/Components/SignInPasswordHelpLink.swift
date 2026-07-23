import SwiftUI

struct SignInPasswordHelpLink: View {
    var body: some View {
        Link(
            destination: URL(
                string: "https://pauljoda.github.io/Prismedia/docs/deployment/authentication#password-recovery"
            )!
        ) {
            Label("Need help signing in?", systemImage: "questionmark.circle")
                .font(.subheadline)
                .foregroundStyle(PrismediaColor.textSecondary)
                .frame(
                    maxWidth: .infinity,
                    minHeight: PrismediaLayout.minimumHitTarget,
                    alignment: .leading
                )
        }
    }
}

#if DEBUG
    #Preview("Sign In Password Help") {
        SignInPasswordHelpLink()
            .frame(maxWidth: SignInLayout.maximumFormWidth)
            .padding(PrismediaSpacing.extraLarge)
            .background(PrismediaBackdrop())
    }
#endif
