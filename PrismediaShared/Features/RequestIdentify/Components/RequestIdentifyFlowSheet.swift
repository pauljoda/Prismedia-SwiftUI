import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestIdentifyFlowSheet<Content: View>: View {
        @Environment(\.dismiss) private var dismiss

        let mode: RequestIdentifyFlowMode
        let phase: RequestIdentifyFlowPhase
        @Binding var path: [RequestIdentifyFlowRoute]
        let showsBackToSearch: Bool
        @ViewBuilder let content: Content

        init(
            mode: RequestIdentifyFlowMode,
            phase: RequestIdentifyFlowPhase,
            path: Binding<[RequestIdentifyFlowRoute]> = .constant([]),
            showsBackToSearch: Bool = false,
            @ViewBuilder content: () -> Content
        ) {
            self.mode = mode
            self.phase = phase
            _path = path
            self.showsBackToSearch = showsBackToSearch
            self.content = content()
        }

        var body: some View {
            NavigationStack(path: $path) {
                content
                    .toolbar {
                        if showsBackToSearch {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Search", systemImage: "chevron.left") {
                                    dismiss()
                                }
                                .prismediaToolbarActionLabelStyle()
                                .disabled(phase.locksDismissal)
                                .accessibilityHint("Returns to the preserved search results")
                            }
                        }

                        ToolbarItem(placement: closePlacement) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                            }
                            .disabled(phase.locksDismissal)
                            .accessibilityLabel("Close \(mode.title)")
                        }
                    }
            }
            .prismediaScreenBackground()
            .interactiveDismissDisabled(phase.locksDismissal)
            .accessibilityIdentifier("request-identify.flow")
        }

        private var closePlacement: ToolbarItemPlacement {
            #if os(iOS)
                .topBarTrailing
            #else
                .confirmationAction
            #endif
        }
    }

    #if DEBUG
        #Preview("Request & Identify Flow Sheet") {
            RequestIdentifyFlowSheet(
                mode: .identify,
                phase: .searchReady
            ) {
                ContentUnavailableView(
                    "Ready to Search",
                    systemImage: "doc.viewfinder"
                )
            }
        }
    #endif
#endif
