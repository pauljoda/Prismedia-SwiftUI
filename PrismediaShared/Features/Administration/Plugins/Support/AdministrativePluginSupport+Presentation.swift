import Foundation

extension AdministrativePluginSupport {
    var contentTypeLabel: String { EntityKind(rawValue: entityKind).displayLabel }

    var actionSummary: String {
        actions.map { action in
            switch action {
            case PrismediaContractCodes.IdentifyAction.search: String(localized: "Search")
            case PrismediaContractCodes.IdentifyAction.lookupId: String(localized: "Identify by ID")
            case PrismediaContractCodes.IdentifyAction.lookupUrl: String(localized: "Identify by URL")
            default: action.replacingOccurrences(of: "-", with: " ").capitalized
            }
        }.joined(separator: " · ")
    }
}
