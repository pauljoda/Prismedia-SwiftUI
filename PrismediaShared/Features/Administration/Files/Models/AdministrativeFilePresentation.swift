import Foundation

enum AdministrativeFilePresentation: Identifiable {
    case details(AdministrativeFileEntry)
    case name(AdministrativeFileNameAction)
    case move(AdministrativeFileEntry)

    var id: String {
        switch self {
        case .details(let entry): "details-\(entry.id)"
        case .name(let action): action.id
        case .move(let entry): "move-\(entry.id)"
        }
    }
}
