import AuthenticationServices
import SwiftUI

struct WelcomeView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            Image(systemName: "mug.fill")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(Palette.amber)
            Text("Brick & Brew")
                .font(.largeTitle.bold())
                .foregroundStyle(Palette.cream)
            Text("The crew scoreboard for triathlon training and well-earned beers.")
                .font(.body)
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
            Spacer()
            if session.isBusy {
                LoadingView(message: "Signing in…")
                    .frame(height: 120)
            } else {
                SignInWithAppleButton(.signIn, onRequest: configure, onCompletion: complete)
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityLabel("Sign in with Apple")
            }
        }
        .padding(Spacing.lg)
    }

    private func configure(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName]
    }

    private func complete(_ result: Result<ASAuthorization, Error>) {
        Task {
            await session.completeAppleSignIn(result)
        }
    }
}
