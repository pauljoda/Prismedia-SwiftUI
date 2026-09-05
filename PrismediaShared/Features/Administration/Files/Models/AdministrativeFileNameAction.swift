import Foundation

enum AdministrativeFileNameAction: Identifiable {
    case createFolder
    case rename(AdministrativeFileEntry)

    var id: String {
        switch self {
        case .createFolder: "create"
        case .rename(let entry): "rename-\(entry.id)"
        }
    }

    var title: String {
        switch self {
        case .createFolder: "New Folder"
        case .rename: "Rename"
        }
    }

    var confirmLabel: String {
        switch self {
        case .createFolder: "Create"
        case .rename: "Rename"
        }
    }
}
