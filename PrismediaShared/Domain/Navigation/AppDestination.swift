import Foundation

/// One destination in the app shell. Content is intentionally metadata-only:
/// the shell owns navigation, while feature modules will own real pages later.
public struct AppDestination: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let systemImage: String
    public let placeholder: String
    public let entityList: EntityListDestination?
    public let administration: AdministrativeDestination?
    #if os(iOS) || os(macOS)
        public let manage: ManageDestination?
    #endif

    public init(
        id: String,
        title: String,
        systemImage: String,
        placeholder: String,
        entityList: EntityListDestination? = nil,
        administration: AdministrativeDestination? = nil
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.placeholder = placeholder
        self.entityList = entityList
        self.administration = administration
        #if os(iOS) || os(macOS)
            manage = nil
        #endif
    }

    #if os(iOS) || os(macOS)
        public init(
            id: String,
            title: String,
            systemImage: String,
            placeholder: String,
            manage: ManageDestination
        ) {
            self.id = id
            self.title = title
            self.systemImage = systemImage
            self.placeholder = placeholder
            entityList = nil
            administration = nil
            self.manage = manage
        }
    #endif
}
