import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifyKindBrowseView: View {
        @Bindable var session: IdentifySession
        let kind: EntityKind

        var body: some View {
            EntityGridView(
                configuration: EntityGridConfiguration(
                    title: kind.displayLabel,
                    query: EntityListQuery(kind: kind, sort: PrismediaContractCodes.EntityListSort.dateAdded),
                    defaultFilters: browseDefaultFilters,
                    supportsSearch: true,
                    defaultDisplayMode: .grid,
                    availableDisplayModes: [.grid, .list],
                    emptyTitle: "No Items to Identify",
                    emptyDescription:
                        "Identify works with imported media. Use Filters to include organized items, or import media first.",
                    preferencesID: "identify:\(kind.rawValue)"
                ),
                loader: session.browseGridLoader,
                preferencesStore: .standard,
                automaticRefreshInterval: .seconds(10),
                startsInSelectionMode: false,
                actionPolicy: actionPolicy,
                topContent: { context in
                    VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                        PrismediaMenuPicker(
                            title: "Identify Provider",
                            systemImage: "sparkles",
                            selectedValue: selectedProvider?.name ?? "No provider available",
                            selection: providerSelection
                        ) {
                            ForEach(eligibleProviders) { provider in
                                Text(provider.name).tag(provider.id)
                            }
                        }
                        .disabled(eligibleProviders.isEmpty)

                        if eligibleProviders.isEmpty {
                            Label(
                                "No enabled provider supports \(kind.displayLabel.lowercased()).",
                                systemImage: "exclamationmark.triangle"
                            )
                            .font(.footnote)
                            .foregroundStyle(PrismediaColor.warning)
                        } else {
                            Text(gridSummary(context))
                                .font(.footnote)
                                .foregroundStyle(PrismediaColor.textSecondary)
                        }
                    }
                    .padding(PrismediaSpacing.large)
                    .prismediaPanel()
                },
                itemContent: { item, layout in
                    EntityThumbnailCardView(item: item, layout: layout)
                }
            )
            .task(id: kind) { session.prepareBrowse(kind: kind) }
            .accessibilityIdentifier("identify.browse")
        }

        private var actionPolicy: EntityGridActionPolicy {
            guard let provider = selectedProvider else { return .disabled }
            return EntityGridActionPolicy(
                selectionEnabled: true,
                customActions: [
                    EntityGridCustomAction(
                        id: "identify",
                        label: "Identify with \(provider.name)",
                        systemImage: "sparkles"
                    ) { items in
                        await session.queueBrowseItems(
                            items,
                            kind: kind,
                            providerID: provider.id
                        )
                    }
                ]
            )
        }

        private var eligibleProviders: [AdministrativePlugin] {
            RequestIdentifyProviderPreferencePolicy.identifyProviders(
                session.providers,
                entityKind: kind.rawValue,
                defaultProviderIDs: session.defaultProviderIDs,
                hidesNsfw: session.hidesNsfw
            )
        }

        private var browseDefaultFilters: EntityGridFilters {
            var filters = EntityGridFilters()
            filters.organization = .unorganized
            return filters
        }

        private var selectedProvider: AdministrativePlugin? {
            eligibleProviders.first { $0.id == session.selectedProviderID }
                ?? eligibleProviders.first
        }

        private var providerSelection: Binding<String> {
            Binding(
                get: { selectedProvider?.id ?? "" },
                set: { session.selectProvider($0) }
            )
        }

        private func gridSummary(_ context: EntityGridTopContentContext) -> String {
            if context.query.organized == false {
                return "Select imported items to find metadata matches."
            }
            return
                "Select imported items to review a new metadata match."
        }
    }

    #if DEBUG
        #Preview("Browse · Content") {
            PreviewShell(signedIn: true) {
                NavigationStack {
                    IdentifyKindBrowseView(
                        session: .init(
                            service: AdministrativePreviewService(),
                            browser: IdentifyPreviewEntityBrowser(),
                            initialProviders: [IdentifyPreviewFixtures.provider]
                        ),
                        kind: .movie
                    )
                }
            }
        }
    #endif
#endif
