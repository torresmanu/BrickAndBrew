import Foundation

enum DisplayName {
    static let maxLength = 32

    static func normalized(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func validated(_ raw: String) throws -> String {
        let name = normalized(raw)
        guard name.isEmpty == false else {
            throw BrickError.missingDisplayName
        }
        guard name.count <= maxLength else {
            throw BrickError.displayNameTooLong
        }
        return name
    }
}
