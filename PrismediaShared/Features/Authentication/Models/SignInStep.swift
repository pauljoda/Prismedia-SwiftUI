enum SignInStep: Equatable {
    case server
    case login(ServerAddress)
    case firstRunSetup(ServerAddress)
}
