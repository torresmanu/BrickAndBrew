import SwiftUI

struct RootView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        Group {
            switch session.phase {
            case .launching:
                LoadingView(message: "Opening the taproom…")
            case .iCloudUnavailable:
                ErrorStateView(
                    message: BrickError.iCloudUnavailable.localizedDescription,
                    retryTitle: "Check again",
                    retry: retryBootstrap
                )
            case .needsAppleSignIn:
                WelcomeView()
            case .needsDisplayName:
                DisplayNameView()
            case .needsJoinCrew:
                JoinCrewView()
            case .needsConnectStrava:
                ConnectStravaView()
            case .ready:
                MainTabView()
            }
        }
        .background(Palette.background.ignoresSafeArea())
        .tint(Palette.amber)
        .alert(
            "Heads up",
            isPresented: bannerBinding,
            actions: {
                Button("OK", action: session.clearBanner)
            },
            message: {
                Text(session.bannerMessage ?? "")
            }
        )
    }

    private var bannerBinding: Binding<Bool> {
        Binding(
            get: { session.bannerMessage != nil && session.phase != .ready },
            set: { isPresented in
                if isPresented == false {
                    session.clearBanner()
                }
            }
        )
    }

    private func retryBootstrap() {
        Task {
            await session.bootstrap()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Crew", systemImage: "trophy") {
                CrewView()
            }
            Tab("Log", systemImage: "mug.fill") {
                LogBeerView()
            }
            Tab("Me", systemImage: "person.crop.circle") {
                MeView()
            }
        }
        .tint(Palette.amber)
        .toolbarBackground(Palette.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
