import SwiftUI

#if os(iOS) || os(macOS)
    struct ManageDestinationView: View {
        let destination: ManageDestination
        let service: any AdministrationServicing
        let fileService: any FileAdministrationServicing
        let client: PrismediaAPIClient
        let detailDependencies: EntityDetailDependencies
        let navigationPath: Binding<[EntityLink]>
        let showsAdministrativeTools: Bool
        let session: AuthSession?

        init(
            destination: ManageDestination,
            service: any AdministrationServicing,
            client: PrismediaAPIClient,
            detailDependencies: EntityDetailDependencies,
            navigationPath: Binding<[EntityLink]>,
            showsAdministrativeTools: Bool,
            session: AuthSession? = nil,
            fileService: (any FileAdministrationServicing)? = nil
        ) {
            self.destination = destination
            self.service = service
            self.client = client
            self.detailDependencies = detailDependencies
            self.navigationPath = navigationPath
            self.showsAdministrativeTools = showsAdministrativeTools
            self.session = session
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
            #if os(iOS)
                if let session, !usesNativePreviewFixtures {
                    EmbeddedAdminContentView(session: session, path: embeddedPath)
                } else {
                    nativeContent
                }
            #else
                nativeContent
            #endif
        }

        private var embeddedPath: String {
            switch destination {
            case .files: "/files?nativeContent"
            case .identify: "/identify?nativeContent"
            case .request: "/request?nativeContent"
            }
        }

        private var usesNativePreviewFixtures: Bool {
            #if DEBUG
                PrismediaUITestBootstrap.usesStep4AdministrationFixtures()
            #else
                false
            #endif
        }

        private var nativeContent: some View {
            Group {
                switch destination {
                case .files: AdministrativeFilesView(service: fileService)
                case .identify:
                    IdentifyView(
                        session: IdentifySession(
                            service: service,
                            browser: PrismediaIdentifyEntityBrowser(client: client),
                            hidesNsfw: !client.allowsNsfwContent
                        )
                    )
                case .request:
                    nativeRequestWorkspace
                }
            }
        }

        private var nativeRequestWorkspace: some View {
            RequestWorkspaceView(
                administrationService: service,
                activityService: client,
                detailDependencies: detailDependencies,
                navigationPath: navigationPath,
                hidesNsfw: !client.allowsNsfwContent,
                showsAdministrativeTools: showsAdministrativeTools,
                resolveAssetURL: client.assetURL
            )
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
                showsAdministrativeTools: true,
                fileService: Step4AdministrationPreviewService()
            )
        }
    #endif
#endif
