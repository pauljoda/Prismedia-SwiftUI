import SwiftUI

struct SignInErrorMessage: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.circle.fill")
            .font(.subheadline)
            .foregroundStyle(PrismediaColor.destructive)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("auth.error")
    }
}

#if DEBUG
    #Preview("Sign In Error") {
        SignInErrorMessage(
            message: "The server couldn’t complete this request. Try again."
        )
        .frame(maxWidth: SignInLayout.maximumFormWidth)
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }

    #Preview("Sign In Error · Accessibility") {
        SignInErrorMessage(
            message: "The server couldn’t complete this request because the supplied credentials were not accepted."
        )
        .frame(maxWidth: SignInLayout.maximumFormWidth)
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
