import Foundation

public struct AdministrativeLibraryEditorTarget: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let root: AdministrativeLibraryRoot?

    public init(root: AdministrativeLibraryRoot? = nil) {
        self.root = root
        id = root?.id ?? UUID()
    }
}
