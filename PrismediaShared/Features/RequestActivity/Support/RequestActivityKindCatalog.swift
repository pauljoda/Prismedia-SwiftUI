import Foundation

public enum RequestActivityKindCatalog {
    public static let wanted: [EntityKind] = RequestKindDefinition.allCases.reduce(into: []) { kinds, definition in
        if !kinds.contains(definition.acquisitionKind) {
            kinds.append(definition.acquisitionKind)
        }
    }
}
