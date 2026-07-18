import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestWorkspaceView: View {
        @State private var section = RequestWorkspaceSection.discover
        @State private var kind = RequestKindDefinition.movie
        @State private var showsAcquisitionSettings = false

        let administrationService: any AdministrationServicing
        let activityService: any RequestActivityServicing
        let detailDependencies: EntityDetailDependencies
        let navigationPath: Binding<[EntityLink]>
        let hidesNsfw: Bool
        let resolveAssetURL: (String) -> URL?

        var body: some View {
            NavigationStack(path: navigationPath) {
                Group {
                    switch section {
                    case .discover:
                        RequestFeatureView(
                            service: administrationService,
                            kind: $kind,
                            hidesNsfw: hidesNsfw,
                            onNavigateToEntity: { intent in
                                openEntity(intent.entityID, intent.entityKind)
                            }
                        )
                    case .activity(let activitySection):
                        RequestActivitySurface(
                            section: activitySection,
                            service: activityService,
                            resolveAssetURL: resolveAssetURL,
                            onOpenEntity: openEntity
                        )
                    }
                }
                .prismediaScreenBackground()
                .navigationTitle("Request")
                #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                #endif
                .safeAreaInset(edge: .top, spacing: 0) {
                    workspaceControls
                }
                .prismediaEntityDestinations(dependencies: detailDependencies)
                .toolbar {
                    ToolbarSpacer(.fixed, placement: trailingToolbarPlacement)
                    ToolbarItem(placement: trailingToolbarPlacement) {
                        Button {
                            showsAcquisitionSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityLabel("Acquisition Settings")
                    }
                }
            }
            .sheet(isPresented: $showsAcquisitionSettings) {
                RequestAcquisitionSettingsView(service: administrationService)
            }
            .accessibilityIdentifier("request.workspace")
        }

        private var sectionPicker: some View {
            Picker("Request View", selection: $section) {
                sectionOptions
            }
            .pickerStyle(.segmented)
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityIdentifier("request.section")
        }

        private var workspaceControls: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                ScrollView(.horizontal) {
                    sectionPicker
                }
                .scrollIndicators(.hidden)

                if section == .discover {
                    LabeledContent("Content Kind") {
                        Picker("Content Kind", selection: $kind) {
                            ForEach(RequestKindDefinition.allCases) { kind in
                                Text(kind.label).tag(kind)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .accessibilityIdentifier("request.kind")
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, PrismediaSpacing.medium)
            .background(.bar)
        }

        @ViewBuilder
        private var sectionOptions: some View {
            ForEach(RequestWorkspaceSection.allCases) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
        }

        private func openEntity(_ entityID: UUID, _ kind: EntityKind) {
            navigationPath.wrappedValue.append(EntityLink(entityID: entityID, kind: kind))
        }

        private var trailingToolbarPlacement: ToolbarItemPlacement {
            #if os(iOS)
                .topBarTrailing
            #else
                .primaryAction
            #endif
        }
    }

    #if DEBUG
        #Preview("Request Workspace") {
            RequestWorkspaceView(
                administrationService: AdministrativePreviewService(),
                activityService: PreviewRequestActivityService(scenario: .content),
                detailDependencies: EntityDetailDependencies(
                    detailLoader: PreviewEntityDetailLoader(detail: EntityDetailPreviewFixture.detail),
                    mutator: nil,
                    collectionItemsLoader: nil,
                    readerService: nil,
                    videoPlaybackService: VideoPlaybackPreviewService(),
                    onEntityMutated: {}
                ),
                navigationPath: .constant([]),
                hidesNsfw: true,
                resolveAssetURL: { URL(string: $0) }
            )
        }
    #endif
#endif
