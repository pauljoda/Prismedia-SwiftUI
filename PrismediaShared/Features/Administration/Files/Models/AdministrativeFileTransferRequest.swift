import Foundation

enum AdministrativeFileTransferRequest: Sendable {
    case upload([URL], AdministrativeFileLocation)
    case download(AdministrativeFileEntry)
    case archive(AdministrativeFileLocation, name: String)

    var isUpload: Bool {
        if case .upload = self { return true }
        return false
    }
}
