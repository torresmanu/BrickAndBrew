import AuthenticationServices
import Foundation

@MainActor
final class AuthService {
    func storedAppleUserId() throws -> String? {
        try KeychainStore.string(for: .appleUserId)
    }

    func persistAppleUserId(_ userId: String) throws {
        try KeychainStore.set(userId, for: .appleUserId)
    }

    func credentialState(for userId: String) async -> ASAuthorizationAppleIDProvider.CredentialState {
        await withCheckedContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userId) { state, _ in
                continuation.resume(returning: state)
            }
        }
    }

    func signOut() throws {
        try KeychainStore.clearSession()
    }

    /// Maps Apple's authorization error to a crew-facing message.
    /// Only `.canceled` is treated as a user dismiss; `.unknown` (code 1000) is
    /// what Apple returns when Sign in with Apple is missing from the App ID.
    nonisolated static func userMessage(forSignInError error: Error) -> String {
        if let authorizationError = error as? ASAuthorizationError, authorizationError.code == .canceled {
            return BrickError.appleSignInCancelled.localizedDescription
        }
        return BrickError.appleSignInFailed.localizedDescription
    }
}
