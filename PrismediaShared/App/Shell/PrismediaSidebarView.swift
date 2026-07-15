import SwiftUI

struct PrismediaSidebarView: View {
    let sections: [AppSidebarSection]
    @Binding var selection: AppSidebarSelection?

    @ViewBuilder
    var body: some View {
        #if os(tvOS)
            sidebarList
                .listStyle(.plain)
        #else
            sidebarList
                .listStyle(.sidebar)
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
        #endif
    }

    private var sidebarList: some View {
        List(selection: $selection) {
            ForEach(sections) { section in
                Section {
                    ForEach(section.items) { item in
                        NavigationLink(value: item.selection) {
                            Label(item.title, systemImage: item.systemImage)
                        }
                        .accessibilityIdentifier("sidebar.\(item.id)")
                    }
                } header: {
                    Text(section.title)
                }
            }
        }
        .navigationTitle("Prismedia")
        .accessibilityIdentifier("shell.sidebar")
    }
}

#if DEBUG
    #Preview("Sectioned App Sidebar") {
        @Previewable @State var selection: AppSidebarSelection? =
            .destination(modeID: "overview", destinationID: "dashboard")

        NavigationSplitView {
            PrismediaSidebarView(
                sections: AppSidebarCatalog.sections(for: PrismediaPreviewData.user),
                selection: $selection
            )
        } detail: {
            ContentUnavailableView("Selected Page", systemImage: "rectangle.split.2x1")
        }
        .frame(width: 1_100, height: 760)
    }
#endif
