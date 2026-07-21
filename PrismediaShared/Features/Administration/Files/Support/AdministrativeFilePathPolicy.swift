import Foundation

public enum AdministrativeFilePathPolicy {
    public static func validatedName(_ value: String) throws -> String {
        let name = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name != ".", name != "..",
            !name.contains("/"), !name.contains("\\"),
            name.rangeOfCharacter(from: .controlCharacters) == nil
        else { throw AdministrativeFileValidationError.invalidName }
        return name
    }

    public static func validatedRelativePath(_ value: String, allowsEmpty: Bool = false) throws -> String {
        let path = value.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "/")
        guard !path.hasPrefix("/") else { throw AdministrativeFileValidationError.absolutePath }
        let parts = path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
        guard allowsEmpty || !parts.isEmpty else { throw AdministrativeFileValidationError.emptyPath }
        guard !parts.contains(".."), !parts.contains(".") else {
            throw AdministrativeFileValidationError.escapingPath
        }
        for part in parts { _ = try validatedName(part) }
        return parts.joined(separator: "/")
    }

    public static func validateMove(sourcePath: String, targetPath: String, sameRoot: Bool) throws {
        let source = try validatedRelativePath(sourcePath)
        let target = try validatedRelativePath(targetPath)
        guard !sameRoot || source != target else { throw AdministrativeFileValidationError.unchangedDestination }
        guard !sameRoot || !target.hasPrefix(source + "/") else {
            throw AdministrativeFileValidationError.descendantDestination
        }
    }
}
