import SwiftUI

public struct PrismediaRootView: View {
    @Environment(PrismediaAppEnvironment.self) private var environment
    @Environment(PrismediaAppRouter.self) private var router

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
        .tint(PrismediaColor.accent)
        .preferredColorScheme(.dark)
        .onOpenURL { url in
            guard let link = PrismediaEntityDeepLink.link(from: url) else { return }
            router.open(link: link)
        }
    }

    private var signedInView: some View {
        PrismediaShellView()
    }

    private var presentation: PrismediaRootPresentation {
        if let presentationOverride {
            return presentationOverride
        }

        if environment.isRestoringSession {
            return .restoring
        }

        return environment.client == nil ? .signedOut : .signedIn
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

            PrismediaLoadingView("Opening your library…")
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
