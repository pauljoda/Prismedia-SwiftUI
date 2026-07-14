import SwiftUI

@main
struct PrismediaiOSApp: App {
    @UIApplicationDelegateAdaptor(PrismediaAppDelegate.self) private var appDelegate
    @State private var environment = PrismediaAppEnvironment()
    #if DEBUG
        @State private var router = PrismediaUITestBootstrap.router() ?? PrismediaAppRouter()
    #else
        @State private var router = PrismediaAppRouter()
    #endif

    var body: some Scene {
        WindowGroup {
            PrismediaRootView()
                .environment(environment)
                .environment(router)
        }
    }
}
