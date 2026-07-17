import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifyKindBrowseView: View {
        @Bindable var session: IdentifySession
        let kind: EntityKind

        var body: some View {
            List(selection: $session.selectedBrowseIDs) {
                ForEach(session.browseItems) { item in
                    Label(item.title, systemImage: item.isOrganized ? "checkmark.circle" : "questionmark.circle")
                        .tag(item.id)
                }
            }
            .prismediaScreenBackground()
            .overlay {
                if session.isBrowsing && session.browseItems.isEmpty {
                    PrismediaLoadingView("Loading \(kind.displayLabel.lowercased()) items…")
                } else if session.isBrowsing {
                    ProgressView("Updating items…")
                } else if session.browseItems.isEmpty {
                    ContentUnavailableView.search(text: session.browseSearch)
                }
            }
            .navigationTitle(kind.displayLabel)
            .searchable(text: $session.browseSearch, prompt: "Search library")
            .toolbar {
                ToolbarItem(placement: trailingToolbarPlacement) {
                    filterMenu
                }

                ToolbarSpacer(.fixed, placement: trailingToolbarPlacement)

                ToolbarItem(placement: trailingToolbarPlacement) {
                    Button {
                        Task { await session.queueSelectedBrowseItems() }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Selected to Queue")
                    .disabled(session.selectedBrowseIDs.isEmpty || session.selectedProviderID.isEmpty)
                }
            }
            .task(id: kind.rawValue + session.browseFilter.rawValue + session.browseSearch) {
                await session.browse(kind: kind)
            }
            .accessibilityIdentifier("identify.browse")
        }

        private var filterMenu: some View {
            Menu {
                Picker("Visibility", selection: $session.browseFilter) {
                    ForEach(IdentifyBrowseFilter.allCases) { Text($0.label).tag($0) }
                }
                Picker("Provider", selection: $session.selectedProviderID) {
                    Text("Choose Provider").tag("")
                    ForEach(eligibleProviders) { Text($0.name).tag($0.id) }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
            }
            .accessibilityLabel("Browse Options")
        }

        private var trailingToolbarPlacement: ToolbarItemPlacement {
            #if os(iOS)
                .topBarTrailing
            #else
                .primaryAction
            #endif
        }

        private var eligibleProviders: [AdministrativePlugin] {
            PluginSearchFieldPolicy.eligibleProviders(
                session.providers,
                entityKind: kind.rawValue,
                hidesNsfw: session.hidesNsfw
            )
        }
    }

    #if DEBUG
        #Preview("Browse · Content") {
            NavigationStack {
                IdentifyKindBrowseView(
                    session: .init(service: AdministrativePreviewService(), browser: IdentifyPreviewEntityBrowser()),
                    kind: .movie)
            }
        }
    #endif
#endif
