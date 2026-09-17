import AuthenticationServices
import SwiftUI

struct WelcomeView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            BrandMark()
                .foregroundStyle(Palette.white)
                .frame(width: 96, height: 96)
                .accessibilityHidden(true)
            Text("Brick & Brew")
                .font(Typography.wordmark)
                .tracking(-1)
                .foregroundStyle(Palette.cream)
            Text("The crew scoreboard for triathlon training and well-earned beers.")
                .font(Typography.body)
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
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.object, style: .continuous))
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
