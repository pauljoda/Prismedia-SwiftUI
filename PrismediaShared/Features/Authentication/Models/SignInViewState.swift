import Foundation

struct SignInViewState: Equatable {
    var step: SignInStep = .server
    var serverURLText = ""
    var username = ""
    var password = ""
    var displayName = ""
    var activity: SignInActivity = .idle
    var errorMessage: String?

    static func login(
        server: ServerAddress,
        username: String = "",
        errorMessage: String? = nil
    ) -> SignInViewState {
        SignInViewState(
            step: .login(server),
            serverURLText: server.url.absoluteString,
            username: username,
            errorMessage: errorMessage
        )
    }

    static func firstRunSetup(server: ServerAddress) -> SignInViewState {
        SignInViewState(
            step: .firstRunSetup(server),
            serverURLText: server.url.absoluteString
        )
    }

    var isBusy: Bool {
        activity != .idle
    }

    var canSubmit: Bool {
        guard !isBusy else { return false }

        switch step {
        case .server:
            return !serverURLText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .login:
            return !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !password.isEmpty
        case .firstRunSetup:
            return !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && password.count >= 8
        }
    }

    var canChangeServer: Bool {
        step != .server && !isBusy
    }

    var primaryActionTitle: String {
        switch activity {
        case .probing:
            return "Connecting…"
        case .signingIn:
            return "Signing In…"
        case .creatingAdmin:
            return "Creating Admin…"
        case .idle:
            switch step {
            case .server:
                return "Continue"
            case .login:
                return "Sign In"
            case .firstRunSetup:
                return "Create Admin"
            }
        }
    }

    var serverDisplayName: String? {
        let server: ServerAddress

        switch step {
        case .server:
            return nil
        case .login(let value), .firstRunSetup(let value):
            server = value
        }

        guard let host = server.url.host() else {
            return server.url.absoluteString
        }

        let authority = server.url.port.map { "\(host):\($0)" } ?? host
        let path = server.url.path == "/" ? "" : server.url.path
        return authority + path
    }

    mutating func returnToServerSelection() {
        guard canChangeServer else { return }

        step = .server
        username = ""
        password = ""
        displayName = ""
        activity = .idle
        errorMessage = nil
    }
}
