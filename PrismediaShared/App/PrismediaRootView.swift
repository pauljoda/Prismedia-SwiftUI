import SwiftUI

public struct PrismediaRootView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(PrismediaAppEnvironment.self) private var environment
    @Environment(PrismediaAppRouter.self) private var router
    @Namespace private var launchBrandNamespace

    private let presentationOverride: PrismediaRootPresentation?
    private let authenticationServiceOverride: (any AuthenticationServicing)?

    public init() {
        presentationOverride = nil
        authenticationServiceOverride = nil
    }

    init(
        previewPresentation: PrismediaRootPresentation,
        authenticationService: (any AuthenticationServicing)? = nil
    ) {
        presentationOverride = previewPresentation
        authenticationServiceOverride = authenticationService
    }

    public var body: some View {
        Group {
            switch presentation {
            case .restoring:
                restoringView
            case .restoringDatabase:
                databaseRestoreView
            case .signedOut:
                signedOutView
            case .signedIn:
                signedInView
                    .task {
                        if presentationOverride == nil {
                            await environment.verifyCurrentSession()
                        }
                    }
            }
        }
        .animation(launchAnimation, value: presentation)
        .tint(PrismediaColor.accent)
        .preferredColorScheme(.dark)
        .onOpenURL { url in
            guard let link = PrismediaEntityDeepLink.link(from: url) else { return }
            router.open(link: link)
        }
        .task(id: scenePhase) {
            guard scenePhase == .active, environment.isRestoringSession else { return }
            await environment.restoreSession()
        }
        .onChange(of: sessionScope) { oldScope, newScope in
            guard let oldScope, oldScope != newScope else { return }
            router.reset()
        }
    }

    private var signedInView: some View {
        PrismediaShellView(launchBrandNamespace: launchBrandNamespace)
    }

    private var launchAnimation: Animation? {
        guard presentation == .signedIn, !reduceMotion else { return nil }
        return .spring(response: 0.58, dampingFraction: 0.84)
    }

    private var presentation: PrismediaRootPresentation {
        if let presentationOverride {
            return presentationOverride
        }

        if environment.isRestoringSession {
            return .restoring
        }

        if environment.databaseRestoreServerURL != nil {
            return .restoringDatabase
        }

        return environment.client == nil ? .signedOut : .signedIn
    }

    private var sessionScope: String? {
        environment.session.map {
            "\($0.serverURL.absoluteString)|\($0.user.id.uuidString.lowercased())"
        }
    }

    @ViewBuilder
    private var databaseRestoreView: some View {
        if let serverURL = environment.databaseRestoreServerURL {
            AdministrativeDatabaseRestoreView(
                service: DatabaseBackupService(client: PrismediaAPIClient(serverURL: serverURL)),
                onFinished: environment.finishDatabaseRestore
            )
        }
    }

    private var restoringView: some View {
        ZStack {
            PrismediaBackdrop()

            RadialGradient(
                colors: [PrismediaColor.accent.opacity(0.1), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 260
            )
            .ignoresSafeArea()

            PrismediaLoadingView(
                "Opening your library…",
                launchBrandNamespace: launchBrandNamespace
            )
            .padding(PrismediaSpacing.section)
        }
        .accessibilityIdentifier("root.restoring")
    }

    @ViewBuilder
    private var signedOutView: some View {
        if let authenticationServiceOverride {
            SignInView(
                previewState: SignInViewState(),
                service: authenticationServiceOverride
            )
        } else {
            SignInView()
        }
    }
}

#if DEBUG
    #Preview("Root · Restoring Session") {
        PreviewShell {
            PrismediaRootView(previewPresentation: .restoring)
        }
    }

    #Preview("Root · Signed Out") {
        PreviewShell {
            PrismediaRootView(
                previewPresentation: .signedOut,
                authenticationService: PreviewAuthenticationService()
            )
        }
    }

    #Preview("Root · Signed In") {
        PreviewShell(signedIn: true) {
            PrismediaRootView(previewPresentation: .signedIn)
        }
    }

    #Preview("Root · Signed In Search") {
        PreviewShell(signedIn: true, initialSearchSelected: true) {
            PrismediaRootView(previewPresentation: .signedIn)
        }
    }
#endif
