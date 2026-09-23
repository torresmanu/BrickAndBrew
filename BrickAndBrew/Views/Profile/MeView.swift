import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit

struct MeView: View {
    @Environment(AppSession.self) private var session
    @State private var viewModel: MeViewModel?
    @State private var confirmDisconnect = false
    @State private var confirmSignOut = false
    @State private var confirmDeleteAccount = false
    @State private var confirmRemoveAvatar = false
    @State private var isEditingName = false

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    MeLoadedView(
                        viewModel: viewModel,
                        confirmDisconnect: $confirmDisconnect,
                        confirmSignOut: $confirmSignOut,
                        confirmDeleteAccount: $confirmDeleteAccount,
                        confirmRemoveAvatar: $confirmRemoveAvatar,
                        isEditingName: $isEditingName
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
    @Binding var confirmDeleteAccount: Bool
    @Binding var confirmRemoveAvatar: Bool
    @Binding var isEditingName: Bool
    @State private var pickerItem: PhotosPickerItem?
    @State private var isChangingCrew = false

    var body: some View {
        List {
            profileSection
            streaksSection
            PintReminderSettingsSection(viewModel: viewModel)
            VenuePingSettingsSection(viewModel: viewModel)
            stravaSection
            sessionSection
        }
        .scrollContentBackground(.hidden)
        .refreshable(action: refreshStreaks)
        .task {
            await viewModel.loadStreaks()
        }
        .onAppear {
            viewModel.refreshVenueAuthorization()
            Task {
                await viewModel.loadStreaks()
            }
        }
        .disabled(viewModel.isDeletingAccount)
        .overlay {
            if viewModel.isDeletingAccount {
                LoadingView(message: "Deleting your account…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Palette.background.opacity(0.92))
                    .allowsHitTesting(true)
            }
        }
        .alert(
            "Heads up",
            isPresented: bannerBinding,
            actions: {
                if viewModel.showsOpenSettings {
                    Button("Open Settings", action: openSettings)
                }
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
        .confirmationDialog("Delete account?", isPresented: $confirmDeleteAccount, titleVisibility: .visible) {
            Button("Delete account", role: .destructive, action: deleteAccount)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes you from the crew board and deletes your training and beers. The crew stays. You will be signed out.")
        }
        .confirmationDialog("Remove photo?", isPresented: $confirmRemoveAvatar, titleVisibility: .visible) {
            Button("Remove photo", role: .destructive, action: removeAvatar)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The crew board will show your initials instead.")
        }
        .sheet(isPresented: $isEditingName) {
            EditDisplayNameSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $isChangingCrew) {
            ChangeCrewSheet(viewModel: viewModel)
        }
    }

    private var profileSection: some View {
        Section {
            HStack(alignment: .center, spacing: Spacing.md) {
                AvatarView(
                    userId: viewModel.profileId,
                    displayName: viewModel.displayName,
                    size: 72,
                    isUpdating: viewModel.isSavingAvatar,
                    cache: session.avatars
                )

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(viewModel.displayName.uppercased())
                        .font(Typography.title)
                        .foregroundStyle(Palette.text)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    Text("CREW CODE  \(viewModel.inviteCode)")
                        .font(Typography.metadata)
                        .foregroundStyle(Palette.secondaryText)
                        .tracking(1.4)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, Spacing.xs)

            photoPickerRow

            Button("Edit name", action: showEditName)
                .disabled(viewModel.isSavingName || viewModel.isSavingAvatar)
            Button("Change crew", action: showChangeCrew)
                .disabled(viewModel.isSavingName || viewModel.isSavingAvatar || viewModel.isSwitchingCrew)

            if viewModel.hasAvatar {
                Button("Remove photo", role: .destructive, action: showRemoveAvatar)
                    .disabled(viewModel.isSavingAvatar)
            }
        }
        .listRowBackground(Palette.surface)
    }

    @ViewBuilder
    private var streaksSection: some View {
        Section {
            switch viewModel.streakState {
            case .loading:
                LoadingView(message: StreakCopy.loadingMessage)
                    .frame(maxWidth: .infinity, minHeight: 140)
                    .listRowInsets(streakRowInsets)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            case .empty:
                EmptyStateView(
                    title: StreakCopy.emptyTitle,
                    message: StreakCopy.emptyMessage,
                    icon: PintSymbol()
                )
                .frame(maxWidth: .infinity, minHeight: 180)
                .listRowInsets(streakRowInsets)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            case .failed(let message):
                ErrorStateView(message: message, retry: retryStreaks)
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .listRowInsets(streakRowInsets)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            case .loaded(let set):
                ForEach(StreakKind.allCases) { kind in
                    StreakCardView(kind: kind, streak: set.streak(for: kind))
                        .listRowInsets(streakRowInsets)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
        } header: {
            Text("Streaks")
        } footer: {
            if case .loaded = viewModel.streakState {
                Text(StreakCopy.brickSyncLag)
                    .foregroundStyle(Palette.secondaryText)
            }
        }
    }

    private var streakRowInsets: EdgeInsets {
        EdgeInsets(top: 6, leading: Spacing.md, bottom: 6, trailing: Spacing.md)
    }

    private var stravaSection: some View {
        Section("Strava") {
            if viewModel.isStravaConnected {
                LabeledContent("Athlete", value: connectedAthleteName)
                Text(viewModel.lastSyncText)
                    .foregroundStyle(Palette.secondaryText)
                if viewModel.isSyncing {
                    HStack {
                        ProgressView()
                            .tint(Palette.accent)
                        Text("Syncing activities…")
                            .foregroundStyle(Palette.secondaryText)
                    }
                } else {
                    Button("Sync now", action: syncNow)
                    Button("Disconnect Strava", role: .destructive, action: showDisconnect)
                }
            } else {
                Text("Connect Strava to pull swim, bike, and run onto the crew board.")
                    .foregroundStyle(Palette.secondaryText)
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
            Button("Delete account", role: .destructive, action: showDeleteAccount)
        } footer: {
            Text("Delete account removes your profile, activities, beers, and pint photos from the crew board.")
                .foregroundStyle(Palette.secondaryText)
        }
        .listRowBackground(Palette.surface)
    }

    private var photoPickerRow: some View {
        let title = viewModel.hasAvatar ? "Change photo" : "Add photo"
        return PhotosPicker(selection: $pickerItem, matching: .images) {
            Text(title)
        }
        .disabled(viewModel.isSavingAvatar)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                await applyPickerItem(item)
            }
        }
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
        viewModel.showsOpenSettings = false
    }

    private func openSettings() {
        viewModel.showsOpenSettings = false
        viewModel.bannerMessage = nil
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
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

    private func showDeleteAccount() {
        confirmDeleteAccount = true
    }

    private func showRemoveAvatar() {
        confirmRemoveAvatar = true
    }

    private func showEditName() {
        viewModel.prepareNameEdit()
        isEditingName = true
    }

    private func showChangeCrew() {
        viewModel.prepareCrewEdit()
        isChangingCrew = true
    }

    private func applyPickerItem(_ item: PhotosPickerItem) async {
        defer { pickerItem = nil }
        do {
            guard let picked = try await item.loadTransferable(type: AvatarPickerData.self) else {
                viewModel.bannerMessage = AvatarImageProcessor.ProcessorError.invalidImage.localizedDescription
                return
            }
            await viewModel.setAvatar(imageData: picked.data)
        } catch {
            viewModel.bannerMessage = AvatarImageProcessor.ProcessorError.invalidImage.localizedDescription
        }
    }

    private func removeAvatar() {
        Task {
            await viewModel.removeAvatar()
        }
    }

    private func deleteAccount() {
        Task {
            await viewModel.deleteAccount()
        }
    }

    private func retryStreaks() {
        Task {
            await viewModel.retryStreaks()
        }
    }

    private func refreshStreaks() async {
        await viewModel.loadStreaks()
    }
}

/// PhotosPicker yields image bytes through this Transferable, not raw `Data`.
private struct AvatarPickerData: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            AvatarPickerData(data: data)
        }
    }
}
