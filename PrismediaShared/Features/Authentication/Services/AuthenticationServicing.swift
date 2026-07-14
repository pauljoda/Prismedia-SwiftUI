@MainActor
protocol AuthenticationServicing: AnyObject {
    func probeServer(urlText: String) async throws -> (address: ServerAddress, setup: SetupStatusResponse)
    func signIn(server: ServerAddress, username: String, password: String) async throws
    func completeFirstRunSetup(
        server: ServerAddress,
        username: String,
        password: String,
        displayName: String?
    ) async throws
}

extension PrismediaAppEnvironment: AuthenticationServicing {}
