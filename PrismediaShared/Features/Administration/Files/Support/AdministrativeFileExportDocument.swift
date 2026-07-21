import SwiftUI
import UniformTypeIdentifiers

#if os(iOS) || os(macOS)
    struct AdministrativeFileExportDocument: FileDocument {
        static var readableContentTypes: [UTType] { [.data] }
        private let data: Data

        init(sourceURL: URL) throws { data = try Data(contentsOf: sourceURL, options: .mappedIfSafe) }

        init(configuration: ReadConfiguration) throws {
            data = configuration.file.regularFileContents ?? Data()
        }

        func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            FileWrapper(regularFileWithContents: data)
        }
    }
#endif
