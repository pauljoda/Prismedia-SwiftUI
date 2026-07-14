import SwiftUI

#if os(iOS) || os(macOS)
    struct ManageDestinationView: View {
        let destination: ManageDestination
        let service: any AdministrationServicing
        let client: PrismediaAPIClient
        let detailDependencies: EntityDetailDependencies
        let navigationPath: Binding<[EntityLink]>

        var body: some View {
            Group {
                switch destination {
                case .files: AdministrativeFilesView(service: service)
                case .identify:
                    IdentifyView(
                        session: IdentifySession(
                            service: service,
                            browser: PrismediaIdentifyEntityBrowser(client: client),
                            hidesNsfw: !client.allowsNsfwContent
                        )
                    )
                case .request:
                    RequestWorkspaceView(
                        administrationService: service,
                        activityService: client,
                        detailDependencies: detailDependencies,
                        navigationPath: navigationPath,
                        hidesNsfw: !client.allowsNsfwContent,
                        resolveAssetURL: client.assetURL
                    )
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
                navigationPath: .constant([])
            )
        }
    #endif
#endif
