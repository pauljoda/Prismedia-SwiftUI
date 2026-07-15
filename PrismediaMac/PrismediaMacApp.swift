import SwiftUI

@main
struct PrismediaMacApp: App {
    @State private var environment = PrismediaAppEnvironment()
    @State private var router = PrismediaAppRouter()

    var body: some Scene {
        WindowGroup {
            PrismediaRootView()
                .environment(environment)
                .environment(router)
                .frame(minWidth: 920, minHeight: 680)
        }
        .defaultSize(width: 1180, height: 780)
        .windowResizability(.contentMinSize)
        .windowToolbarStyle(.unified)
        .commands {
            PrismediaMacCommands(environment: environment, router: router)
        }
    }
}
