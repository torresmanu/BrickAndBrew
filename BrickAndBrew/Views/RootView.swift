import SwiftUI

struct RootView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        Group {
            switch session.phase {
            case .launching:
                if session.hasStoredSession {
                    SplashView()
                } else {
                    LoadingView(message: "Opening the taproom…")
                }
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
        .tint(Palette.accent)
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
    @Environment(AppSession.self) private var session
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var session = session
        TabView(selection: $session.selectedTab) {
            Tab("Crew", systemImage: "trophy", value: AppTab.crew) {
                CrewView()
            }
            Tab(value: AppTab.log) {
                LogBeerView()
            } label: {
                Label {
                    Text("Log")
                } icon: {
                    Image(uiImage: PintSymbol.tabBarImage)
                        .renderingMode(.original)
                }
            }
            Tab(value: AppTab.me) {
                MeView()
            } label: {
                Label {
                    Text("Me")
                } icon: {
                    Image(uiImage: meTabIcon)
                        .renderingMode(.original)
                }
            }
        }
        .tint(Palette.accent)
        .toolbarBackground(Palette.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            VenueVisitMonitor.shared.refreshMonitoring()
            Task {
                await session.refreshPintReminderFromCloud()
            }
        }
        .task {
            await session.requestFirstRunReminderPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openLogTab)) { _ in
            session.selectedTab = .log
        }
    }

    /// Original-color circular photo so the tab bar does not flatten it to a template glyph.
    private var meTabIcon: UIImage {
        _ = session.avatars.generation
        let profile = session.profile
        let photo = profile.flatMap { session.avatars.image(for: $0.id) }
        return TabBarAvatar.image(
            photo: photo,
            displayName: profile?.displayName ?? "Me"
        )
    }
}
