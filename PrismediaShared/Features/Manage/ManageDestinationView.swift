import SwiftUI

#if os(iOS) || os(macOS)
    struct ManageDestinationView: View {
        let destination: ManageDestination
        let service: any AdministrationServicing
        let fileService: any FileAdministrationServicing
        let client: PrismediaAPIClient
        let detailDependencies: EntityDetailDependencies
        let navigationPath: Binding<[EntityLink]>

        init(
            destination: ManageDestination,
            service: any AdministrationServicing,
            client: PrismediaAPIClient,
            detailDependencies: EntityDetailDependencies,
            navigationPath: Binding<[EntityLink]>,
            fileService: (any FileAdministrationServicing)? = nil
        ) {
            self.destination = destination
            self.service = service
            self.client = client
            self.detailDependencies = detailDependencies
            self.navigationPath = navigationPath
            if let fileService {
                self.fileService = fileService
            } else {
                #if DEBUG
                    self.fileService =
                        PrismediaUITestBootstrap.usesStep4AdministrationFixtures()
                        ? Step4AdministrationPreviewService()
                        : FileAdministrationService(client: client)
                #else
                    self.fileService = FileAdministrationService(client: client)
                #endif
            }
        }

        var body: some View {
            Group {
                switch destination {
                case .files: AdministrativeFilesView(service: fileService)
                case .identify:
                    #if os(macOS)
                        MacIdentifyView(
                            session: IdentifySession(
                                service: service,
                                browser: PrismediaIdentifyEntityBrowser(client: client),
                                hidesNsfw: !client.allowsNsfwContent
                            )
                        )
                    #else
                        IdentifyView(
                            session: IdentifySession(
                                service: service,
                                browser: PrismediaIdentifyEntityBrowser(client: client),
                                hidesNsfw: !client.allowsNsfwContent
                            )
                        )
                    #endif
                case .request:
                    #if os(macOS)
                        MacRequestWorkspaceView(
                            administrationService: service,
                            activityService: client,
                            detailDependencies: detailDependencies,
                            navigationPath: navigationPath,
                            hidesNsfw: !client.allowsNsfwContent,
                            resolveAssetURL: client.assetURL
                        )
                    #else
                        RequestWorkspaceView(
                            administrationService: service,
                            activityService: client,
                            detailDependencies: detailDependencies,
                            navigationPath: navigationPath,
                            hidesNsfw: !client.allowsNsfwContent,
                            resolveAssetURL: client.assetURL
                        )
                    #endif
                }
            }
        }
    }

    #if DEBUG
        #Preview {
            ManageDestinationView(
                destination: .files,
                service: AdministrativePreviewService(),
                client: PrismediaAPIClient(serverURL: URL(string: "https://example.com")!),
                detailDependencies: EntityDetailDependencies(
                    detailLoader: PreviewEntityDetailLoader(detail: EntityDetailPreviewFixture.detail),
                    mutator: nil,
                    collectionItemsLoader: nil,
                    readerService: nil,
                    videoPlaybackService: VideoPlaybackPreviewService(),
                    onEntityMutated: {}
                ),
                navigationPath: .constant([]),
                fileService: Step4AdministrationPreviewService()
            )
        }
    #endif
#endif
