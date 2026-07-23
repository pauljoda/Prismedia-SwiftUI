import SwiftUI

struct SignInPrimaryActionButton: View {
    let title: String
    let isBusy: Bool
    let canSubmit: Bool
    let action: () -> Void

    var body: some View {
        PrismediaButton(
            title,
            variant: .prominent,
            form: .fill,
            isLoading: isBusy,
            action: action
        )
        .disabled(!canSubmit)
        .accessibilityIdentifier("auth.primary")
    }
}

#if DEBUG
    #Preview("Sign In Action · States") {
        VStack(spacing: PrismediaSpacing.large) {
            SignInPrimaryActionButton(
                title: "Continue",
                isBusy: false,
                canSubmit: true,
                action: {}
            )
            SignInPrimaryActionButton(
                title: "Sign In",
                isBusy: true,
                canSubmit: true,
                action: {}
            )
            SignInPrimaryActionButton(
                title: "Create Administrator",
                isBusy: false,
                canSubmit: false,
                action: {}
            )
        }
        .frame(maxWidth: SignInLayout.maximumFormWidth)
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }
#endif
