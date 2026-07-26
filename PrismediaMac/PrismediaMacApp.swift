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
        .defaultSize(width: 1_280, height: 820)
        .windowResizability(.contentMinSize)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            PrismediaMacUndoRedoCommands()
            PrismediaMacCommands(environment: environment, router: router)
            PrismediaNsfwCommands(environment: environment)
            InspectorCommands()
        }
    }
}
