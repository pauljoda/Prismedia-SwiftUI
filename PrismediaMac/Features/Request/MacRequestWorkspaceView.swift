#if os(macOS)
    import SwiftUI

    struct MacRequestWorkspaceView: View {
        @State private var section = RequestWorkspaceSection.discover
        @State private var kind: RequestKindDefinition?
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
                    MacWorkspaceHeaderView(
                        title: "Request",
                        subtitle: "Discover and add new media, then follow every acquisition through completion.",
                        systemImage: "paperplane.fill",
                        accent: PrismediaColor.materialSpectrumViolet
                    )

                    sectionBar

                    Divider()

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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .prismediaScreenBackground()
                .navigationTitle(section.title)
                .prismediaEntityDestinations(dependencies: detailDependencies)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showsAcquisitionSettings = true
                        } label: {
                            Label("Acquisition Settings", systemImage: "gearshape")
                                .foregroundStyle(PrismediaColor.materialSpectrumViolet)
                        }
                    }
                }
            }
            .sheet(isPresented: $showsAcquisitionSettings) {
                RequestAcquisitionSettingsView(service: administrationService)
                    .frame(minWidth: 620, minHeight: 560)
            }
            .accessibilityIdentifier("request.workspace")
        }

        private var sectionBar: some View {
            ScrollView(.horizontal) {
                HStack(spacing: PrismediaSpacing.extraLarge) {
                    ForEach(RequestWorkspaceSection.allCases) { candidate in
                        Button {
                            section = candidate
                        } label: {
                            VStack(spacing: PrismediaSpacing.small) {
                                Label(candidate.title, systemImage: candidate.systemImage)
                                    .font(.callout.weight(section == candidate ? .semibold : .regular))
                                    .foregroundStyle(
                                        section == candidate
                                            ? PrismediaColor.textPrimary
                                            : PrismediaColor.textSecondary
                                    )

                                Rectangle()
                                    .fill(
                                        section == candidate
                                            ? PrismediaColor.materialSpectrumViolet
                                            : .clear
                                    )
                                    .frame(height: 2)
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(section == candidate ? .isSelected : [])
                    }
                }
                .padding(.horizontal, PrismediaSpacing.extraExtraLarge)
            }
            .scrollIndicators(.hidden)
            .accessibilityIdentifier("request.section")
        }

        private func openEntity(_ entityID: UUID, _ kind: EntityKind) {
            navigationPath.wrappedValue.append(EntityLink(entityID: entityID, kind: kind))
        }
    }

    #if DEBUG
        #Preview("Mac Request Workspace") {
            PreviewShell(signedIn: true) {
                MacRequestWorkspaceView(
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
            .frame(width: 980, height: 720)
        }
    #endif
#endif
