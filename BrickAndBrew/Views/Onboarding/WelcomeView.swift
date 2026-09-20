import AuthenticationServices
import SwiftUI

struct WelcomeView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        ZStack(alignment: .bottom) {
            Image(BrandPhoto.welcomeHero)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay {
                    LinearGradient(
                        colors: [Color.clear, Palette.ink.opacity(0.35), Palette.ink],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.lg) {
                BrandWordmark()
                Text("SPORT TAKEN SERIOUSLY.\nEVERYTHING AFTER, LESS SO.")
                    .font(Typography.body)
                    .foregroundStyle(Palette.paper)
                    .fixedSize(horizontal: false, vertical: true)

                if session.isBusy {
                    LoadingView(message: "Signing in…")
                        .frame(height: 120)
                } else {
                    SignInWithAppleButton(.signIn, onRequest: configure, onCompletion: complete)
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
                        .accessibilityLabel("Sign in with Apple")
                }
            }
            .padding(Spacing.lg)
            .padding(.bottom, Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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
