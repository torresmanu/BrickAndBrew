import SwiftUI

/// Brand hold shown on cold launch when a session is already in the Keychain.
/// New users skip this and land on Welcome once bootstrap finishes.
struct SplashView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didAppear = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            BrandMark()
                .foregroundStyle(Palette.paper)
                .frame(width: 88, height: 88)
                .accessibilityHidden(true)
            BrandWordmark(alignment: .center)
                .frame(maxWidth: .infinity)
            Spacer()
            status
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.black.ignoresSafeArea())
        .brandAppear(isReducedMotion: reduceMotion, trigger: didAppear)
        .onAppear { didAppear = true }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var status: some View {
        VStack(spacing: Spacing.sm) {
            ProgressView()
                .tint(Palette.paper)
            if let greeting {
                Text(greeting)
                    .font(Typography.metadata)
                    .foregroundStyle(Palette.paper)
                    .tracking(2)
                    .multilineTextAlignment(.center)
            }
            Text("Loading the crew board…")
                .font(Typography.body)
                .foregroundStyle(Palette.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, Spacing.sm)
    }

    /// Profile lands during bootstrap while phase is still launching, so a returning name can show.
    private var greeting: String? {
        let name = session.profile?.displayName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard name.isEmpty == false else { return nil }
        return GreetingCopy.headline(name: name)
    }

    private var accessibilityText: String {
        if let greeting {
            return "Brick & Brew. \(greeting). Loading the crew board."
        }
        return "Brick & Brew. Loading the crew board."
    }
}
