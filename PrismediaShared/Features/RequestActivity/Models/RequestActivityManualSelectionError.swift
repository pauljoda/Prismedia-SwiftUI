import Foundation

enum RequestActivityManualSelectionError: LocalizedError {
    case noFiles
    case folderUnsupported(String)
    case unreadable(String)
    case empty(String)
    case duplicate(String)
    case overLimit
    case unsupportedPrimary(EntityKind)
    case torrentRequired

    var errorDescription: String? {
        switch self {
        case .noFiles:
            "Choose at least one file."
        case .folderUnsupported(let name):
            "\(name) is a folder. Choose the files inside it instead."
        case .unreadable(let name):
            "\(name) could not be read. Choose it again or select another file."
        case .empty(let name):
            "\(name) is empty. Choose a non-empty file."
        case .duplicate(let name):
            "More than one selected file is named \(name). Remove the duplicate before uploading."
        case .overLimit:
            "The selected files exceed Prismedia’s 250 GiB acquisition upload limit."
        case .unsupportedPrimary(let kind):
            "The selection does not contain supported \(kind.displayLabel.lowercased()) content."
        case .torrentRequired:
            "Choose one non-empty .torrent file."
        }
    }
}
