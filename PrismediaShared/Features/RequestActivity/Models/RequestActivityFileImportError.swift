import Foundation

enum RequestActivityFileImportError: LocalizedError {
    case noFileSelected

    var errorDescription: String? {
        "No torrent file was selected."
    }
}
