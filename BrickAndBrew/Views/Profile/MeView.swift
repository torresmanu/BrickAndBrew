import SwiftUI

struct MeView: View {
    @Environment(AppSession.self) private var session
    @State private var viewModel: MeViewModel?
    @State private var confirmDisconnect = false
    @State private var confirmSignOut = false

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    MeLoadedView(
                        viewModel: viewModel,
                        confirmDisconnect: $confirmDisconnect,
                        confirmSignOut: $confirmSignOut
                    )
                } else {
                    LoadingView(message: "Loading your profile…")
                }
            }
            .background(Palette.background.ignoresSafeArea())
            .navigationTitle("Me")
        }
        .onAppear(perform: ensureViewModel)
    }

    private func ensureViewModel() {
        if viewModel == nil {
            viewModel = MeViewModel(session: session)
        }
    }
}

private struct MeLoadedView: View {
    @Environment(AppSession.self) private var session
    @Bindable var viewModel: MeViewModel
    @Binding var confirmDisconnect: Bool
    @Binding var confirmSignOut: Bool

    var body: some View {
        List {
            profileSection
            stravaSection
            sessionSection
        }
        .scrollContentBackground(.hidden)
        .alert(
            "Strava",
            isPresented: bannerBinding,
            actions: {
                Button("OK", action: dismissBanner)
            },
            message: {
                Text(viewModel.bannerMessage ?? "")
            }
        )
        .confirmationDialog("Disconnect Strava?", isPresented: $confirmDisconnect, titleVisibility: .visible) {
            Button("Disconnect", role: .destructive, action: disconnect)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Training already on the board stays. New activities won't sync until you reconnect.")
        }
        .confirmationDialog("Sign out?", isPresented: $confirmSignOut, titleVisibility: .visible) {
            Button("Sign out", role: .destructive, action: session.signOut)
            Button("Cancel", role: .cancel) {}
        }
    }

    private var profileSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(viewModel.displayName)
                    .font(.title2.bold())
                    .foregroundStyle(Palette.cream)
                Text("Crew code \(viewModel.inviteCode)")
                    .font(.subheadline)
                    .foregroundStyle(Palette.muted)
                    .textSelection(.enabled)
            }
            .padding(.vertical, Spacing.xs)
        }
        .listRowBackground(Palette.surface)
    }

    private var stravaSection: some View {
        Section("Strava") {
            if viewModel.isStravaConnected {
                LabeledContent("Athlete", value: connectedAthleteName)
                Text(viewModel.lastSyncText)
                    .foregroundStyle(Palette.muted)
                if viewModel.isSyncing {
                    HStack {
                        ProgressView()
                            .tint(Palette.amber)
                        Text("Syncing activities…")
                            .foregroundStyle(Palette.muted)
                    }
                } else {
                    Button("Sync now", action: syncNow)
                    Button("Disconnect Strava", role: .destructive, action: showDisconnect)
                }
            } else {
                Text("Connect Strava to pull swim, bike, and run onto the crew board.")
                    .foregroundStyle(Palette.muted)
                if AppConfig.isStravaConfigured {
                    Button("Connect with Strava", action: connect)
                        .foregroundStyle(Palette.stravaOrange)
                } else {
                    Text(BrickError.missingStravaConfiguration.localizedDescription)
                        .foregroundStyle(Palette.danger)
                }
            }
        }
        .listRowBackground(Palette.surface)
    }

    private var sessionSection: some View {
        Section {
            Button("Sign out", role: .destructive, action: showSignOut)
        }
        .listRowBackground(Palette.surface)
    }

    private var connectedAthleteName: String {
        let name = viewModel.stravaName ?? ""
        return name.isEmpty ? "Connected" : name
    }

    private var bannerBinding: Binding<Bool> {
        Binding(
            get: { viewModel.bannerMessage != nil },
            set: { isPresented in
                if isPresented == false {
                    viewModel.bannerMessage = nil
                }
            }
        )
    }

    private func dismissBanner() {
        viewModel.bannerMessage = nil
    }

    private func connect() {
        Task {
            await viewModel.connectStrava()
        }
    }

    private func syncNow() {
        Task {
            await viewModel.syncNow()
        }
    }

    private func disconnect() {
        Task {
            await viewModel.disconnectStrava()
        }
    }

    private func showDisconnect() {
        confirmDisconnect = true
    }

    private func showSignOut() {
        confirmSignOut = true
    }
}
