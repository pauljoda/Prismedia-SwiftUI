import SwiftUI

struct SignInForm: View {
    @Binding var state: SignInViewState
    @Binding var showsPassword: Bool

    let focusedField: FocusState<Field?>.Binding
    let onAdvance: () -> Void
    let onPasswordSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraLarge) {
            switch state.step {
            case .server:
                serverField
            case .login:
                usernameField
                passwordField(isNewPassword: false)
            case .firstRunSetup:
                usernameField
                passwordField(isNewPassword: true)
                displayNameField
            }
        }
    }

    private var serverField: some View {
        fieldGroup(title: "Server address") {
            TextField("prismedia.example.com", text: $state.serverURLText)
                .prismediaTextInputStyle()
                .controlSize(.large)
                .prismediaPlainTextInput()
                .autocorrectionDisabled()
                .accessibilityLabel("Server URL")
                .accessibilityIdentifier("auth.server.field")
                .focused(focusedField, equals: .server)
                .submitLabel(.go)
                #if os(iOS) || os(tvOS)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                #endif
                .onSubmit(onAdvance)
        }
    }

    private var usernameField: some View {
        fieldGroup(title: "Username") {
            TextField("Username", text: $state.username)
                .prismediaTextInputStyle()
                .controlSize(.large)
                .prismediaPlainTextInput()
                .autocorrectionDisabled()
                .accessibilityLabel("Username")
                .accessibilityIdentifier("auth.username.field")
                .focused(focusedField, equals: .username)
                .submitLabel(.next)
                #if os(iOS) || os(tvOS)
                    .textContentType(.username)
                #endif
                .onSubmit { focusedField.wrappedValue = .password }
        }
    }

    private func passwordField(isNewPassword: Bool) -> some View {
        fieldGroup(
            title: "Password",
            hint: isNewPassword ? "Use at least 8 characters." : nil
        ) {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                Group {
                    if showsPassword {
                        TextField("Password", text: $state.password)
                    } else {
                        SecureField("Password", text: $state.password)
                    }
                }
                .prismediaTextInputStyle()
                .controlSize(.large)
                .prismediaCredentialTextInput()
                .accessibilityLabel("Password")
                .accessibilityIdentifier("auth.password.field")
                .focused(focusedField, equals: .password)
                .submitLabel(isLoginStep ? .go : .next)
                #if os(iOS) || os(tvOS)
                    .textContentType(isNewPassword ? .newPassword : .password)
                #endif
                .onSubmit(onPasswordSubmit)

                #if os(tvOS)
                    Toggle(isOn: $showsPassword) {
                        Label(
                            showsPassword ? "Hide Password" : "Show Password",
                            systemImage: showsPassword ? "eye.slash" : "eye"
                        )
                        .foregroundStyle(PrismediaColor.textSecondary)
                    }
                    .toggleStyle(.switch)
                    .accessibilityIdentifier("auth.password.visibility")
                #endif
            }
        }
    }

    private var displayNameField: some View {
        fieldGroup(title: "Display name", hint: "Optional") {
            TextField("How your name appears", text: $state.displayName)
                .prismediaTextInputStyle()
                .controlSize(.large)
                .accessibilityLabel("Display name")
                .accessibilityIdentifier("auth.display-name.field")
                .focused(focusedField, equals: .displayName)
                .submitLabel(.go)
                #if os(iOS) || os(tvOS)
                    .textContentType(.name)
                #endif
                .onSubmit(onAdvance)
        }
    }

    private func fieldGroup<Content: View>(
        title: String,
        hint: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            Text(title)
                .font(fieldLabelFont)
                .foregroundStyle(.primary)

            content()

            if let hint {
                Text(hint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var fieldLabelFont: Font {
        #if os(tvOS)
            .headline.weight(.semibold)
        #else
            .subheadline.weight(.medium)
        #endif
    }

    private var isLoginStep: Bool {
        if case .login = state.step {
            return true
        }
        return false
    }
}

#if DEBUG
    #Preview("Sign In Form · Server") {
        @Previewable @State var state = SignInViewState(
            serverURLText: "prismedia.example.com"
        )
        @Previewable @State var showsPassword = false
        @Previewable @FocusState var focusedField: Field?

        SignInForm(
            state: $state,
            showsPassword: $showsPassword,
            focusedField: $focusedField,
            onAdvance: {},
            onPasswordSubmit: {}
        )
        .frame(maxWidth: SignInLayout.maximumFormWidth)
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }

    #Preview("Sign In Form · Login") {
        @Previewable @State var state = SignInViewState.login(
            server: try! ServerAddress(text: "prismedia.example.com"),
            username: "paul"
        )
        @Previewable @State var showsPassword = false
        @Previewable @FocusState var focusedField: Field?

        SignInForm(
            state: $state,
            showsPassword: $showsPassword,
            focusedField: $focusedField,
            onAdvance: {},
            onPasswordSubmit: {}
        )
        .frame(maxWidth: SignInLayout.maximumFormWidth)
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }

    #Preview("Sign In Form · Setup Accessibility") {
        @Previewable @State var state = SignInViewState.firstRunSetup(
            server: try! ServerAddress(text: "prismedia.example.com")
        )
        @Previewable @State var showsPassword = true
        @Previewable @FocusState var focusedField: Field?

        SignInForm(
            state: $state,
            showsPassword: $showsPassword,
            focusedField: $focusedField,
            onAdvance: {},
            onPasswordSubmit: {}
        )
        .frame(maxWidth: SignInLayout.maximumFormWidth)
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
