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
                    passwordHelp: { SignInPasswordHelpLink() }
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
                            .frame(maxWidth: SignInLayout.maximumFormWidth)
                            .padding(.horizontal, PrismediaSpacing.extraExtraLarge)
                            .padding(
                                .vertical,
                                compact
                                    ? PrismediaSpacing.extraLarge
                                    : PrismediaSpacing.section
                            )
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
        VStack(
            alignment: .leading,
            spacing: compact
                ? PrismediaSpacing.extraLarge
                : PrismediaSpacing.extraExtraLarge + PrismediaSpacing.extraSmall
        ) {
            SignInHeader(
                title: title,
                subtitle: subtitle,
                serverName: state.serverDisplayName,
                isCompact: compact
            )
            SignInForm(
                state: $state,
                showsPassword: $showsPassword,
                focusedField: $focusedField,
                onAdvance: advance,
                onPasswordSubmit: submitPassword
            )

            if let errorMessage = state.errorMessage {
                errorMessageView(errorMessage)
            }

            if isLoginStep {
                SignInPasswordHelpLink()
            }
        }
    }

    private var form: some View {
        SignInForm(
            state: $state,
            showsPassword: $showsPassword,
            focusedField: $focusedField,
            onAdvance: advance,
            onPasswordSubmit: submitPassword
        )
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

    private func errorMessageView(_ message: String) -> some View {
        SignInErrorMessage(message: message)
            .accessibilityFocused($errorIsFocused)
    }

    private var bottomAction: some View {
        SignInPrimaryActionButton(
            title: state.primaryActionTitle,
            isBusy: state.isBusy,
            canSubmit: state.canSubmit,
            action: advance
        )
        .frame(maxWidth: SignInLayout.maximumFormWidth)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, PrismediaSpacing.extraExtraLarge)
        .padding(.top, PrismediaSpacing.medium)
        .padding(.bottom, PrismediaSpacing.small)
    }

    private var primaryActionSystemImage: String {
        switch state.step {
        case .server: "arrow.right"
        case .login: "person.crop.circle.badge.checkmark"
        case .firstRunSetup: "person.crop.circle.badge.plus"
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
        .prismediaToolbarActionLabelStyle()
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
            || availableHeight < SignInLayout.compactHeightThreshold
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
