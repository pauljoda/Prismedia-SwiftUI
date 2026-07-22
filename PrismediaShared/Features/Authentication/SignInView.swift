import SwiftUI

/// Native Prismedia authentication: server discovery, existing-user sign-in,
/// and first-run administrator creation in one keyboard-safe flow.
public struct SignInView: View {
    @Environment(PrismediaAppEnvironment.self) private var environment
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @FocusState private var focusedField: Field?
    @AccessibilityFocusState private var errorIsFocused: Bool

    @State private var state: SignInViewState
    #if os(tvOS)
        // tvOS 27's SwiftUI SecureField dismisses its keyboard when the ABC mode
        // is selected and drops hardware-keyboard Shift. Start in the native
        // TextField path so mixed-case passwords remain enterable, then mask on
        // submission or whenever the user turns visibility off.
        @State private var showsPassword = true
    #else
        @State private var showsPassword = false
    #endif

    private let serviceOverride: (any AuthenticationServicing)?

    public init() {
        serviceOverride = nil
        _state = State(initialValue: SignInViewState())
    }

    init(
        previewState: SignInViewState,
        service: (any AuthenticationServicing)? = nil
    ) {
        serviceOverride = service
        _state = State(initialValue: previewState)
    }

    public var body: some View {
        Group {
            #if os(tvOS)
                TVSignInSurface(
                    title: title,
                    subtitle: subtitle,
                    serverName: state.serverDisplayName,
                    primaryActionTitle: state.primaryActionTitle,
                    primaryActionSystemImage: primaryActionSystemImage,
                    isBusy: state.isBusy,
                    canSubmit: state.canSubmit,
                    showsChangeServer: state.step != .server,
                    showsPasswordHelp: isLoginStep,
                    errorMessage: state.errorMessage,
                    onAdvance: advance,
                    form: { form },
                    changeServer: { changeServerButton },
                    errorContent: errorMessageView,
                    passwordHelp: { passwordHelpLink }
                )
            #else
                compactPlatformBody
            #endif
        }
        .onChange(of: state.errorMessage) { _, message in
            errorIsFocused = message != nil
        }
        .onAppear {
            guard state.serverURLText.isEmpty,
                let rememberedServer = environment.lastServerURL
            else { return }
            state.serverURLText = rememberedServer.absoluteString
        }
    }

    private var compactPlatformBody: some View {
        NavigationStack {
            GeometryReader { geometry in
                let compact = usesCompactLayout(availableHeight: geometry.size.height)

                ZStack {
                    PrismediaBackdrop()

                    ScrollView {
                        authenticationContent(compact: compact)
                            .frame(maxWidth: 420)
                            .padding(.horizontal, PrismediaSpacing.extraExtraLarge)
                            .padding(.vertical, compact ? 20 : 32)
                            .frame(maxWidth: .infinity)
                            .frame(
                                minHeight: geometry.size.height,
                                alignment: compact ? .top : .center
                            )
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .prismediaKeyboardDismissal()
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomAction
            }
            .navigationTitle("")
            .prismediaInlineNavigationTitle()
            .toolbar {
                if state.step != .server {
                    ToolbarItem(placement: .cancellationAction) {
                        changeServerButton
                    }
                }
            }
        }
    }

    private func authenticationContent(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 20 : 28) {
            header(compact: compact)
            form

            if let errorMessage = state.errorMessage {
                errorMessageView(errorMessage)
            }

            if isLoginStep {
                passwordHelpLink
            }
        }
    }

    private func header(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
            PrismediaBrandView(
                markSize: compact
                    ? PrismediaLayout.compactBrandMark
                    : PrismediaLayout.brandMark
            )
            .frame(maxWidth: .infinity)

            Text(title)
                .font(compact ? .title.bold() : .largeTitle.bold())
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let serverName = state.serverDisplayName {
                Label(serverName, systemImage: "server.rack")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    @ViewBuilder
    private var form: some View {
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
                .focused($focusedField, equals: .server)
                .submitLabel(.go)
                #if os(iOS) || os(tvOS)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                #endif
                .onSubmit(advance)
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
                .focused($focusedField, equals: .username)
                .submitLabel(.next)
                #if os(iOS) || os(tvOS)
                    .textContentType(.username)
                #endif
                .onSubmit { focusedField = .password }
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
                .focused($focusedField, equals: .password)
                .submitLabel(isLoginStep ? .go : .next)
                #if os(iOS) || os(tvOS)
                    .textContentType(isNewPassword ? .newPassword : .password)
                #endif
                .onSubmit(submitPassword)

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

    private func submitPassword() {
        #if os(tvOS)
            showsPassword = false
        #endif
        if isLoginStep {
            advance()
            return
        }
        focusedField = .displayName
    }

    private var displayNameField: some View {
        fieldGroup(title: "Display name", hint: "Optional") {
            TextField("How your name appears", text: $state.displayName)
                .prismediaTextInputStyle()
                .controlSize(.large)
                .accessibilityLabel("Display name")
                .accessibilityIdentifier("auth.display-name.field")
                .focused($focusedField, equals: .displayName)
                .submitLabel(.go)
                #if os(iOS) || os(tvOS)
                    .textContentType(.name)
                #endif
                .onSubmit(advance)
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

    private func errorMessageView(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.circle.fill")
            .font(.subheadline)
            .foregroundStyle(PrismediaColor.destructive)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("auth.error")
            .accessibilityFocused($errorIsFocused)
    }

    private var bottomAction: some View {
        primaryActionButton
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, PrismediaSpacing.extraExtraLarge)
            .padding(.top, PrismediaSpacing.medium)
            .padding(.bottom, PrismediaSpacing.small)
    }

    private var primaryActionButton: some View {
        PrismediaButton(
            state.primaryActionTitle,
            variant: .prominent,
            form: .fill,
            isLoading: state.isBusy,
            action: advance
        )
        .disabled(!state.canSubmit)
        .accessibilityIdentifier("auth.primary")
    }

    private var primaryActionSystemImage: String {
        switch state.step {
        case .server: "arrow.right"
        case .login: "person.crop.circle.badge.checkmark"
        case .firstRunSetup: "person.crop.circle.badge.plus"
        }
    }

    private var passwordHelpLink: some View {
        Link(
            destination: URL(
                string: "https://pauljoda.github.io/Prismedia/docs/deployment/authentication#password-recovery")!
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

    private var changeServerButton: some View {
        Button {
            state.returnToServerSelection()
            focusedField = nil
        } label: {
            Label("Change Server", systemImage: "chevron.backward")
                #if os(tvOS)
                    .foregroundStyle(PrismediaColor.textSecondary)
                #endif
        }
        .disabled(!state.canChangeServer)
        .accessibilityLabel("Choose a different server")
        .accessibilityIdentifier("auth.change-server")
    }

    private var title: String {
        switch state.step {
        case .server:
            return "Connect to Prismedia"
        case .login:
            return "Welcome back"
        case .firstRunSetup:
            return "Set up Prismedia"
        }
    }

    private var subtitle: String {
        switch state.step {
        case .server:
            return "Enter the address you use to open your library."
        case .login:
            return "Sign in to continue to your library."
        case .firstRunSetup:
            return "Create the administrator account for this server."
        }
    }

    private var authenticationService: any AuthenticationServicing {
        serviceOverride ?? environment
    }

    private var isLoginStep: Bool {
        if case .login = state.step {
            return true
        }
        return false
    }

    private func usesCompactLayout(availableHeight: CGFloat) -> Bool {
        verticalSizeClass == .compact
            || dynamicTypeSize.isAccessibilitySize
            || availableHeight < 560
    }

    private func advance() {
        guard state.canSubmit else { return }

        let submittedStep = state.step
        #if os(tvOS)
            if case .login = submittedStep {
                showsPassword = false
            }
        #endif
        state.activity = activity(for: submittedStep)
        state.errorMessage = nil
        focusedField = nil

        Task {
            defer { state.activity = .idle }

            do {
                try await submit(submittedStep)
            } catch {
                state.errorMessage = AuthenticationErrorMessage.message(for: error)
            }
        }
    }

    private func activity(for step: SignInStep) -> SignInActivity {
        switch step {
        case .server:
            return .probing
        case .login:
            return .signingIn
        case .firstRunSetup:
            return .creatingAdmin
        }
    }

    private func submit(_ submittedStep: SignInStep) async throws {
        switch submittedStep {
        case .server:
            let result = try await authenticationService.probeServer(urlText: state.serverURLText)
            state.step =
                result.setup.needsSetup
                ? .firstRunSetup(result.address)
                : .login(result.address)
            state.errorMessage = nil
            focusedField = .username

        case .login(let server):
            try await authenticationService.signIn(
                server: server,
                username: state.username,
                password: state.password
            )

        case .firstRunSetup(let server):
            let name = state.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            try await authenticationService.completeFirstRunSetup(
                server: server,
                username: state.username,
                password: state.password,
                displayName: name.isEmpty ? nil : name
            )
        }
    }
}

#if DEBUG
    private let previewAuthServer = try! ServerAddress(text: "prismedia.local:8008")

    #if os(iOS)
        #Preview("Connect · iPhone") {
            PreviewShell {
                SignInView(
                    previewState: SignInViewState(serverURLText: "prismedia.local:8008"),
                    service: PreviewAuthenticationService()
                )
            }
        }

        #Preview("Sign In · iPhone") {
            PreviewShell {
                SignInView(
                    previewState: .login(server: previewAuthServer, username: "paul"),
                    service: PreviewAuthenticationService()
                )
            }
        }

        #Preview("First Admin · iPhone") {
            PreviewShell {
                SignInView(
                    previewState: .firstRunSetup(server: previewAuthServer),
                    service: PreviewAuthenticationService(needsSetup: true)
                )
            }
        }

        #Preview("Invalid Credentials") {
            PreviewShell {
                SignInView(
                    previewState: .login(
                        server: previewAuthServer,
                        username: "paul",
                        errorMessage: "Invalid username or password."
                    ),
                    service: PreviewAuthenticationService()
                )
            }
        }

        #Preview("Signing In") {
            var previewState = SignInViewState.login(server: previewAuthServer, username: "paul")
            previewState.password = "preview-password"
            previewState.activity = .signingIn

            return PreviewShell {
                SignInView(
                    previewState: previewState,
                    service: PreviewAuthenticationService()
                )
            }
        }

        #Preview("First Admin · Accessibility XXXL") {
            var previewState = SignInViewState.firstRunSetup(server: previewAuthServer)
            previewState.errorMessage = "The server couldn’t complete this request. Try again."

            return PreviewShell {
                SignInView(
                    previewState: previewState,
                    service: PreviewAuthenticationService(needsSetup: true)
                )
                .environment(\.dynamicTypeSize, .accessibility5)
            }
        }

        #Preview("First Admin · Compact Height") {
            PreviewShell {
                SignInView(
                    previewState: .firstRunSetup(server: previewAuthServer),
                    service: PreviewAuthenticationService(needsSetup: true)
                )
            }
            .frame(width: 393, height: 420)
        }

        #Preview("First Admin · Landscape") {
            PreviewShell {
                SignInView(
                    previewState: .firstRunSetup(server: previewAuthServer),
                    service: PreviewAuthenticationService(needsSetup: true)
                )
            }
            .frame(width: 844, height: 390)
        }

        #Preview("Sign In · iPad") {
            PreviewShell {
                SignInView(
                    previewState: .login(server: previewAuthServer, username: "paul"),
                    service: PreviewAuthenticationService()
                )
            }
            .frame(width: 1024, height: 1366)
        }
    #elseif os(macOS)
        #Preview("macOS · Sign In") {
            PreviewShell {
                SignInView(
                    previewState: .login(server: previewAuthServer, username: "paul"),
                    service: PreviewAuthenticationService()
                )
            }
            .frame(width: 1000, height: 720)
        }
    #elseif os(tvOS)
        #Preview("tvOS · Sign In") {
            PreviewShell {
                SignInView(
                    previewState: .login(server: previewAuthServer, username: "paul"),
                    service: PreviewAuthenticationService()
                )
            }
        }
    #endif
#endif
