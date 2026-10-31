import SwiftUI

struct PrismediaSidebarView: View {
    let sections: [AppSidebarSection]
    @Binding var selection: AppSidebarSelection?
    /// While iPhone Duo is folded like a book, the width that ends the sidebar at
    /// the fold, so the sidebar and the page each keep to one side.
    var foldedWidth: CGFloat?

    @ViewBuilder
    var body: some View {
        #if os(macOS)
            MacPrismediaSidebarView(selection: $selection, sections: sections)
        #elseif os(tvOS)
            sidebarList
                .listStyle(.plain)
        #else
            // The shell's detail column carries the sidebar toggle, so it joins the
            // side bar on iPhone Duo instead of sitting beside the brand.
            sidebarList
                .listStyle(.sidebar)
                .toolbar(removing: .sidebarToggle)
                .navigationSplitViewColumnWidth(
                    min: foldedWidth ?? 200,
                    ideal: foldedWidth ?? 240,
                    max: foldedWidth ?? 320
                )
        #endif
    }

    @ViewBuilder
    private var sidebarList: some View {
        #if os(iOS)
            List {
                sidebarSections
            }
            .prismediaScreenBackground()
            .navigationTitle("Prismedia")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    PrismediaSidebarBrandView(markSize: 24)
                }
            }
            .accessibilityIdentifier("shell.sidebar")
        #else
            List(selection: $selection) {
                sidebarSections
            }
            .prismediaScreenBackground()
            .navigationTitle("Prismedia")
            .accessibilityIdentifier("shell.sidebar")
        #endif
    }

    private var sidebarSections: some View {
        ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
            let accent = PrismediaSidebarPalette.accent(
                for: section.id,
                fallbackIndex: index
            )

            Section {
                ForEach(section.items) { item in
                    #if os(iOS)
                        sidebarButton(item, accent: accent)
                    #else
                        NavigationLink(value: item.selection) {
                            sidebarLabel(item, accent: accent)
                        }
                        .accessibilityIdentifier("sidebar.\(item.id)")
                    #endif
                }
            } header: {
                Text(section.title)
                    .foregroundStyle(accent)
            }
        }
    }

    #if os(iOS)
        private func sidebarButton(
            _ item: AppSidebarItem,
            accent: Color
        ) -> some View {
            let isSelected = selection == item.selection

            return Button {
                selection = item.selection
            } label: {
                sidebarLabel(item, accent: accent)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .frame(
                        maxWidth: .infinity,
                        minHeight: PrismediaLayout.minimumHitTarget,
                        alignment: .leading
                    )
                    .padding(.horizontal, PrismediaSpacing.medium)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(PrismediaColor.controlFill)
                        }
                    }
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .listRowInsets(
                EdgeInsets(
                    top: PrismediaSpacing.extraExtraSmall,
                    leading: PrismediaSpacing.small,
                    bottom: PrismediaSpacing.extraExtraSmall,
                    trailing: PrismediaSpacing.small
                )
            )
            .listRowBackground(Color.clear)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityIdentifier("sidebar.\(item.id)")
        }
    #endif

    private func sidebarLabel(
        _ item: AppSidebarItem,
        accent: Color
    ) -> some View {
        Label {
            Text(item.title)
                .foregroundStyle(PrismediaColor.textPrimary)
        } icon: {
            Image(systemName: item.systemImage)
                .foregroundStyle(accent)
        }
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
