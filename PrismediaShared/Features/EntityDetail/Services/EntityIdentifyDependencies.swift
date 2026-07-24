import Foundation

public struct EntityIdentifyDependencies: Sendable {
    let administration: any AdministrationServicing
    let browser: any IdentifyEntityBrowsing
    let hidesNsfw: Bool
    let onOpenProviders: @MainActor @Sendable () -> Void

    public init(
        administration: any AdministrationServicing,
        browser: any IdentifyEntityBrowsing,
        hidesNsfw: Bool,
        onOpenProviders: @escaping @MainActor @Sendable () -> Void
    ) {
        self.administration = administration
        self.browser = browser
        self.hidesNsfw = hidesNsfw
        self.onOpenProviders = onOpenProviders
    }
}
