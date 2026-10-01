import Foundation

@MainActor
@Observable
final class MeViewModel {
    var isSyncing = false
    var isDeletingAccount = false
    var isSavingAvatar = false
    var isSavingName = false
    var draftName = ""
    var nameEditMessage: String?
    var isSwitchingCrew = false
    var draftCrewCode = ""
    var crewEditMessage: String?
    var lastSyncText: String
    var bannerMessage: String?
    var streakState: LoadState<StreakSet> = .loading

    private let session: AppSession
    private var streakLoadGeneration = 0

    init(session: AppSession) {
        self.session = session
        if let last = SyncCursor.lastSyncAt() {
            lastSyncText = "Last Strava sync \(Formatters.relative(last))"
        } else {
            lastSyncText = "No Strava sync yet"
        }
    }

    var displayName: String {
        session.profile?.displayName ?? "Teammate"
    }

    var profileId: String {
        session.profile?.id ?? ""
    }

    var hasAvatar: Bool {
        session.profile?.hasAvatar == true
    }

    var inviteCode: String {
        session.team?.inviteCode ?? "—"
    }

    var stravaName: String? {
        session.profile?.stravaAthleteName
    }

    var isStravaConnected: Bool {
        session.profile?.isStravaConnected == true
    }

    func loadStreaks() async {
        streakLoadGeneration += 1
        let generation = streakLoadGeneration
        switch streakState {
        case .loaded, .empty:
            break
        default:
            streakState = .loading
        }

        do {
            guard let profile = session.profile, let team = session.team else {
                throw BrickError.missingProfile
            }

            async let beersTask = session.cloudKit.fetchBeers(userId: profile.id, teamId: team.id)
            async let activitiesTask = session.cloudKit.fetchActivities(teamId: team.id, since: team.seasonStart)
            let seasonBeers = try await beersTask.filter { $0.loggedAt >= team.seasonStart }
            let mine = try await activitiesTask.filter { $0.userId == profile.id }
            let set = StreakCalculator.summarize(
                activities: mine,
                beers: seasonBeers,
                seasonStart: team.seasonStart
            )
            // Empty is "never logged this season." A gap still shows the training streak.
            let hasHistory = seasonBeers.isEmpty == false || mine.isEmpty == false
            guard generation == streakLoadGeneration else { return }
            streakState = hasHistory ? .loaded(set) : .empty
        } catch {
            guard generation == streakLoadGeneration else { return }
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            switch streakState {
            case .loaded, .empty:
                bannerMessage = message
            default:
                streakState = .failed(message)
            }
        }
    }

    func syncNow() async {
        guard isSyncing == false else { return }
        isSyncing = true
        defer { isSyncing = false }
        let previousBrick = currentBrickCount
        do {
            let count = try await session.syncStravaActivities()
            lastSyncText = "Last Strava sync \(Formatters.relative(Date()))"
            await loadStreaks()
            bannerMessage = brickSyncBanner(syncedCount: count, previousBrick: previousBrick)
        } catch {
            bannerMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func connectStrava() async {
        await session.connectStrava()
        if let last = SyncCursor.lastSyncAt() {
            lastSyncText = "Last Strava sync \(Formatters.relative(last))"
        }
        bannerMessage = session.bannerMessage
        session.clearBanner()
        await loadStreaks()
    }

    func disconnectStrava() async {
        await session.disconnectStrava()
        lastSyncText = "No Strava sync yet"
        await loadStreaks()
    }

    func deleteAccount() async {
        guard isDeletingAccount == false else { return }
        isDeletingAccount = true
        defer { isDeletingAccount = false }
        await session.deleteAccount()
        if session.phase != .needsAppleSignIn {
            bannerMessage = session.bannerMessage
            session.clearBanner()
        }
    }

    func retryStreaks() async {
        await loadStreaks()
    }

    func setAvatar(imageData: Data) async {
        guard isSavingAvatar == false else { return }
        isSavingAvatar = true
        defer { isSavingAvatar = false }

        do {
            let jpeg = try AvatarImageProcessor.makeAvatarJPEG(from: imageData)
            try await session.saveProfileAvatar(jpegData: jpeg)
        } catch {
            bannerMessage = (error as? LocalizedError)?.errorDescription
                ?? "We couldn't save your photo. Check your connection and try again."
        }
    }

    func removeAvatar() async {
        guard isSavingAvatar == false else { return }
        isSavingAvatar = true
        defer { isSavingAvatar = false }

        do {
            try await session.removeProfileAvatar()
        } catch {
            bannerMessage = (error as? LocalizedError)?.errorDescription
                ?? "We couldn't remove your photo. Check your connection and try again."
        }
    }

    func prepareNameEdit() {
        draftName = displayName
        nameEditMessage = nil
    }

    var canSaveName: Bool {
        let name = DisplayName.normalized(draftName)
        return isSavingName == false
            && name.isEmpty == false
            && name != displayName
            && name.count <= DisplayName.maxLength
    }

    func saveDisplayName() async -> Bool {
        guard isSavingName == false else { return false }
        isSavingName = true
        nameEditMessage = nil
        defer { isSavingName = false }

        do {
            try await session.updateDisplayName(draftName)
            Haptics.success()
            return true
        } catch {
            nameEditMessage = (error as? LocalizedError)?.errorDescription
                ?? "We couldn't save your name. Check your connection and try again."
            Haptics.warning()
            return false
        }
    }

    func prepareCrewEdit() {
        draftCrewCode = ""
        crewEditMessage = nil
    }

    var canSwitchCrew: Bool {
        guard isSwitchingCrew == false else { return false }
        return (try? CrewSwitch.validatedCode(currentInviteCode: inviteCode, draft: draftCrewCode)) != nil
    }

    func switchCrew() async -> Bool {
        guard isSwitchingCrew == false else { return false }
        isSwitchingCrew = true
        crewEditMessage = nil
        defer { isSwitchingCrew = false }

        do {
            try await session.switchCrew(inviteCode: draftCrewCode)
            Haptics.success()
            streakState = .loading
            await loadStreaks()
            if case .failed = streakState {
                return true
            }
            bannerMessage = "You're on crew \(inviteCode)."
            return true
        } catch {
            crewEditMessage = (error as? LocalizedError)?.errorDescription
                ?? "We couldn't switch crews. Check your connection and try again."
            Haptics.warning()
            return false
        }
    }

    private var currentBrickCount: Int {
        if case .loaded(let set) = streakState {
            return set.brick.current
        }
        return 0
    }

    private func brickSyncBanner(syncedCount: Int, previousBrick: Int) -> String {
        if case .loaded(let set) = streakState, set.brick.current > previousBrick {
            return StreakCopy.cheerAfterBrick(days: set.brick.current)
        }
        if syncedCount == 0 {
            return "You're up to date. No new activities. \(StreakCopy.brickSyncLag)"
        }
        let synced = syncedCount == 1 ? "Synced 1 activity." : "Synced \(syncedCount) activities."
        return "\(synced) \(StreakCopy.brickSyncLag)"
    }
}
