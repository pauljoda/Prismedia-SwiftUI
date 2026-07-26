import SwiftUI

struct PrismediaSidebarView: View {
    let sections: [AppSidebarSection]
    @Binding var selection: AppSidebarSelection?

    @ViewBuilder
    var body: some View {
        #if os(macOS)
            MacPrismediaSidebarView(selection: $selection, sections: sections)
        #elseif os(tvOS)
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
            ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                let accent = PrismediaSidebarPalette.accent(
                    for: section.id,
                    fallbackIndex: index
                )

                Section {
                    ForEach(section.items) { item in
                        NavigationLink(value: item.selection) {
                            Label {
                                Text(item.title)
                                    .foregroundStyle(PrismediaColor.textPrimary)
                            } icon: {
                                Image(systemName: item.systemImage)
                                    .foregroundStyle(
                                        selection == item.selection
                                            ? PrismediaColor.textPrimary
                                            : accent
                                    )
                            }
                        }
                        .accessibilityIdentifier("sidebar.\(item.id)")
                    }
                } header: {
                    Text(section.title)
                        .foregroundStyle(accent)
                }
            }
        }
        .prismediaScreenBackground()
        .navigationTitle("Prismedia")
        #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    PrismediaSidebarBrandView(markSize: 24)
                }
            }
        #endif
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
