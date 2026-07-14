import Observation

/// Stable focus signal shared by tvOS content and its tab shell.
///
/// Content publishes intent by advancing the generation. The shell remains the
/// sole owner of focus state and resolves the request against its selected tab.
@MainActor
@Observable
final class TVTabFocusCoordinator {
    private(set) var requestGeneration = 0

    func requestFocus() {
        requestGeneration += 1
    }
}
