import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestWorkspaceView: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @State private var section = RequestWorkspaceSection.discover
        @State private var kind: RequestKindDefinition?
        @State private var showsAcquisitionSettings = false

        let administrationService: any AdministrationServicing
        let activityService: any RequestActivityServicing
        let detailDependencies: EntityDetailDependencies
        let navigationPath: Binding<[EntityLink]>
        let hidesNsfw: Bool
        let showsAdministrativeTools: Bool
        let resolveAssetURL: (String) -> URL?

        var body: some View {
            NavigationStack(path: navigationPath) {
                Group {
                    if usesWideWorkspace {
                        VStack(spacing: 0) {
                            PrismediaWorkspaceHeaderView(
                                title: "Request",
                                subtitle:
                                    "Discover and add new media, then follow every acquisition through completion.",
                                systemImage: "paperplane.fill",
                                accent: PrismediaColor.materialSpectrumViolet
                            )

                            if showsAdministrativeTools {
                                RequestWorkspaceSectionBar(selection: $section)
                                Divider()
                            }

                            sectionContent
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    } else {
                        sectionContent
                    }
                }
                .prismediaScreenBackground()
                .navigationTitle(section.title)
                #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarTitleMenu {
                        if showsAdministrativeTools {
                            sectionPicker
                        }
                    }
                #endif
                .prismediaEntityDestinations(dependencies: detailDependencies)
                .toolbar {
                    if showsAdministrativeTools {
                        ToolbarSpacer(.fixed, placement: trailingToolbarPlacement)
                        ToolbarItem(placement: trailingToolbarPlacement) {
                            Button {
                                showsAcquisitionSettings = true
                            } label: {
                                if usesWideWorkspace {
                                    Label("Acquisition Settings", systemImage: "gearshape")
                                        .foregroundStyle(PrismediaColor.materialSpectrumViolet)
                                } else {
                                    Image(systemName: "gearshape")
                                }
                            }
                            .accessibilityLabel("Acquisition Settings")
                        }
                    }
                }
            }
            .sheet(isPresented: $showsAcquisitionSettings) {
                RequestAcquisitionSettingsView(service: administrationService)
                    .frame(
                        minWidth: settingsSheetMinimumWidth,
                        minHeight: settingsSheetMinimumHeight
                    )
            }
            .accessibilityIdentifier("request.workspace")
        }

        @ViewBuilder
        private var sectionContent: some View {
            switch (showsAdministrativeTools, section) {
            case (false, _), (true, .discover):
                RequestFeatureView(
                    service: administrationService,
                    kind: $kind,
                    hidesNsfw: hidesNsfw,
                    onNavigateToEntity: { intent in
                        openEntity(intent.entityID, intent.entityKind)
                    }
                )
            case (true, .activity(let activitySection)):
                RequestActivitySurface(
                    section: activitySection,
                    service: activityService,
                    resolveAssetURL: resolveAssetURL,
                    onOpenEntity: openEntity,
                    onEnterReleaseDate: openReleaseDateEditor
                )
            }
        }

        private var sectionPicker: some View {
            Picker("Request View", selection: $section) {
                ForEach(RequestWorkspaceSection.allCases) { section in
                    Label(section.title, systemImage: section.systemImage)
                        .tag(section)
                }
            }
            .accessibilityIdentifier("request.section")
        }

        private func openEntity(_ entityID: UUID, _ kind: EntityKind) {
            navigationPath.wrappedValue.append(EntityLink(entityID: entityID, kind: kind))
        }

        private func openReleaseDateEditor(_ entityID: UUID, _ kind: EntityKind) {
            navigationPath.wrappedValue.append(
                EntityLink(entityID: entityID, kind: kind, intent: .editReleaseDate)
            )
        }

        private var trailingToolbarPlacement: ToolbarItemPlacement {
            #if os(iOS)
                .topBarTrailing
            #else
                .primaryAction
            #endif
        }

        private var usesWideWorkspace: Bool {
            #if os(macOS)
                true
            #else
                horizontalSizeClass == .regular
            #endif
        }

        private var settingsSheetMinimumWidth: CGFloat? {
            #if os(macOS)
                620
            #else
                nil
            #endif
        }

        private var settingsSheetMinimumHeight: CGFloat? {
            #if os(macOS)
                560
            #else
                nil
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
                showsAdministrativeTools: true,
                resolveAssetURL: { URL(string: $0) }
            )
        }
    #endif
#endif
