import Foundation

/// Only a successfully loaded server folder may be confirmed as a library location.
struct AdministrativeLibraryFolderSelection {
    private var loading = AdministrativeCollectionLoadState<AdministrativeLibraryBrowseResponse>()
    var folder: AdministrativeLibraryBrowseResponse? { loading.items.first }
    var isLoading: Bool { loading.isLoading }
    var errorMessage: String? { loading.errorMessage }
    var selectedPath: String? { isLoading || errorMessage != nil ? nil : folder?.path }

    mutating func begin() -> Int { loading.begin(clearingItems: true) }

    mutating func succeed(
        _ folder: AdministrativeLibraryBrowseResponse, request: Int, isCancelled: Bool = false
    ) {
        loading.succeed([folder], request: request, isCancelled: isCancelled)
    }

    mutating func fail(_ error: any Error, request: Int, isCancelled: Bool) {
        loading.fail(error, request: request, isCancelled: isCancelled)
    }
}
