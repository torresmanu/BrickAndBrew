import Foundation

/// A profile stores one `teamId`. Switching crews is a move, not a second membership.
enum CrewSwitch {
    /// Returns the crew code to join, or why this draft cannot replace the current one.
    static func validatedCode(currentInviteCode: String, draft: String) throws -> String {
        let code = InviteCode.normalized(draft)
        guard InviteCode.isValid(code) else {
            throw BrickError.invalidInviteCode
        }
        if InviteCode.normalized(currentInviteCode) == code {
            throw BrickError.alreadyOnCrew
        }
        return code
    }
}
