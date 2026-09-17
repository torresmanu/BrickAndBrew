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
}
