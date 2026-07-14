import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestWorkspaceView: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @State private var section = RequestWorkspaceSection.discover
        @State private var showsAcquisitionSettings = false

        let administrationService: any AdministrationServicing
        let activityService: any RequestActivityServicing
        let detailDependencies: EntityDetailDependencies
        let navigationPath: Binding<[EntityLink]>
        let hidesNsfw: Bool
        let resolveAssetURL: (String) -> URL?

        var body: some View {
            NavigationStack(path: navigationPath) {
                VStack(spacing: 0) {
                    sectionPicker
                        .padding(.horizontal)
                        .padding(.vertical, PrismediaSpacing.medium)

                    Divider()

                    switch section {
                    case .discover:
                        RequestFeatureView(
                            service: administrationService,
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
                .prismediaEntityDestinations(dependencies: detailDependencies)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Settings", systemImage: "gearshape") {
                            showsAcquisitionSettings = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showsAcquisitionSettings) {
                RequestAcquisitionSettingsView(service: administrationService)
            }
            .accessibilityIdentifier("request.workspace")
        }

        @ViewBuilder
        private var sectionPicker: some View {
            if horizontalSizeClass == .compact {
                Picker("Request Section", selection: $section) {
                    sectionOptions
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Picker("Request Section", selection: $section) {
                    sectionOptions
                }
                .pickerStyle(.segmented)
            }
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
