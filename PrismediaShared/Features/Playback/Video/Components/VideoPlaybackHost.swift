import SwiftUI

struct VideoPlaybackHost<Content: View>: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var session: VideoPlaybackSession
    private let content: (VideoPlaybackSession) -> Content
    private let onRestore: (EntityLink) -> Void

    init(
        client: PrismediaAPIClient,
        preferences: VideoPlaybackPreferences = VideoPlaybackPreferences(),
        onRestore: @escaping (EntityLink) -> Void,
        @ViewBuilder content: @escaping (VideoPlaybackSession) -> Content
    ) {
        #if os(iOS) || os(tvOS)
            let systemPlayback = VideoNowPlayingCoordinator(service: client).integration
        #else
            let systemPlayback = VideoSystemPlaybackIntegration.inactive
        #endif
        #if os(tvOS)
            let displayCriteria = TVVideoDisplayCriteriaCoordinator().integration
        #else
            let displayCriteria = VideoDisplayCriteriaIntegration.inactive
        #endif
        _session = State(
            initialValue: VideoPlaybackSession(
                service: client,
                preferences: preferences,
                systemPlayback: systemPlayback,
                displayCriteria: displayCriteria
            )
        )
        self.onRestore = onRestore
        self.content = content
    }

    var body: some View {
        content(session)
            .environment(\.videoPlaybackSession, session)
            .onAppear { session.onRestoreNavigation = onRestore }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .background else { return }
                session.flushPlaybackProgress()
            }
            .onDisappear {
                #if !os(tvOS)
                    session.reset()
                #endif
            }
    }
}

#if DEBUG
    #Preview("Video Playback Host") {
        VideoPlaybackHost(
            client: PrismediaPreviewData.model(signedIn: true).client!,
            onRestore: { _ in },
            content: { _ in
                Text("Video library").frame(maxWidth: .infinity, maxHeight: .infinity).background(PrismediaBackdrop())
            }
        )
    }
#endif
