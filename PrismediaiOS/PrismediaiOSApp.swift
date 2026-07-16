import SwiftUI

@main
struct PrismediaiOSApp: App {
    @UIApplicationDelegateAdaptor(PrismediaAppDelegate.self) private var appDelegate
    @State private var environment = PrismediaAppEnvironment()
    @State private var musicPlayback = MusicPlaybackComposition()
    #if DEBUG
        @State private var router = PrismediaUITestBootstrap.router() ?? PrismediaAppRouter()
    #else
        @State private var router = PrismediaAppRouter()
    #endif

    var body: some Scene {
        WindowGroup {
            MusicPlaybackLifecycleHost(playback: musicPlayback) {
                PrismediaRootView()
                    .environment(router)
            }
            .environment(environment)
        }
    }
}
