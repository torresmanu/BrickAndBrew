import AuthenticationServices
import SwiftUI
import UIKit

struct WelcomeView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didAppear = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Spacer()
            BrandWordmark()
            Text("SPORT TAKEN SERIOUSLY.\nEVERYTHING AFTER, LESS SO.")
                .font(Typography.displayM)
                .foregroundStyle(Palette.paper)
                .minimumScaleFactor(0.65)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            signInControl
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Palette.black.ignoresSafeArea())
        .brandAppear(isReducedMotion: reduceMotion, trigger: didAppear)
        .onAppear { didAppear = true }
    }

    @ViewBuilder
    private var signInControl: some View {
        if session.isBusy {
            signingInStatus
        } else {
            AppleSignInButton(onRequest: configure, onCompletion: complete)
                .frame(height: AppleSignInButton.controlHeight)
                .clipShape(Capsule(style: .continuous))
                .accessibilityLabel("Sign in with Apple")
        }
    }

    private var signingInStatus: some View {
        HStack(spacing: Spacing.sm) {
            ProgressView()
                .tint(Palette.paper)
            Text("Signing in…")
                .font(Typography.body)
                .foregroundStyle(Palette.paper)
        }
        .frame(maxWidth: .infinity)
        .frame(height: AppleSignInButton.controlHeight)
        .accessibilityElement(children: .combine)
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

/// Official Apple button sized to a capsule so the corners match the iPhone's continuous radius.
private struct AppleSignInButton: UIViewRepresentable {
    static let controlHeight: CGFloat = 52

    var onRequest: (ASAuthorizationAppleIDRequest) -> Void
    var onCompletion: (Result<ASAuthorization, Error>) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onRequest: onRequest, onCompletion: onCompletion)
    }

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .white)
        button.cornerRadius = Self.controlHeight / 2
        button.clipsToBounds = true
        button.addTarget(context.coordinator, action: #selector(Coordinator.handleTap), for: .touchUpInside)
        context.coordinator.button = button
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        uiView.cornerRadius = Self.controlHeight / 2
        context.coordinator.onRequest = onRequest
        context.coordinator.onCompletion = onCompletion
        context.coordinator.button = uiView
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: ASAuthorizationAppleIDButton,
        context: Context
    ) -> CGSize? {
        CGSize(width: proposal.width ?? uiView.intrinsicContentSize.width, height: Self.controlHeight)
    }

    final class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        var onRequest: (ASAuthorizationAppleIDRequest) -> Void
        var onCompletion: (Result<ASAuthorization, Error>) -> Void
        weak var button: ASAuthorizationAppleIDButton?

        init(
            onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void,
            onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void
        ) {
            self.onRequest = onRequest
            self.onCompletion = onCompletion
        }

        @objc func handleTap() {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            onRequest(request)
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        func authorizationController(
            controller: ASAuthorizationController,
            didCompleteWithAuthorization authorization: ASAuthorization
        ) {
            onCompletion(.success(authorization))
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            onCompletion(.failure(error))
        }

        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            if let window = button?.window {
                return window
            }
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
        }
    }
}
