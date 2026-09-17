import Foundation

enum InviteCode {
    static func normalized(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    static func isValid(_ code: String) -> Bool {
        let allowed = CharacterSet.alphanumerics
        return (4...20).contains(code.count) && code.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
}
