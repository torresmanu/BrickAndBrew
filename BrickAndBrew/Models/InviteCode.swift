import Foundation

enum InviteCode {
    static let minLength = 4
    static let maxLength = 20

    static func normalized(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    static func isValid(_ code: String) -> Bool {
        let allowed = CharacterSet.alphanumerics
        return (minLength...maxLength).contains(code.count) && code.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
}
