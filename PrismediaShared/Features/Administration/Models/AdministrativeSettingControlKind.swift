import Foundation

public enum AdministrativeSettingControlKind: Hashable, Sendable {
    case boolean
    case integer
    case decimal
    case select
    case text
    case stringList
    case unsupported
}
