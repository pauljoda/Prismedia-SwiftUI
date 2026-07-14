import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityEmptyView: View {
        let section: RequestActivitySection
        let state: RequestActivityEmptyState
        let query: String

        var body: some View {
            if state == .filtered {
                ContentUnavailableView.search(text: query)
            } else {
                ContentUnavailableView(
                    title,
                    systemImage: section.systemImage,
                    description: Text(message)
                )
            }
        }

        private var title: String {
            switch section {
            case .downloads: "Nothing Downloading"
            case .missing: "Nothing Is Missing"
            case .cutoffUnmet: "Nothing Below Cutoff"
            case .history: "No Acquisition Activity"
            }
        }

        private var message: String {
            switch section {
            case .downloads:
                "Request something from Discover and its download will appear here."
            case .missing:
                "Monitored items not yet acquired will appear here."
            case .cutoffUnmet:
                "Upgradable items still chasing a better release will appear here."
            case .history:
                "Grabs, imports, failures, and removals will appear here."
            }
        }
    }

    #if DEBUG
        #Preview("Request Activity Empty") {
            RequestActivityEmptyView(section: .missing, state: .empty, query: "")
        }
    #endif
#endif
