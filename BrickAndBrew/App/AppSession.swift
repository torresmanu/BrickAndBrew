import AuthenticationServices
import Foundation

enum SessionPhase: Equatable {
    case launching
    case needsAppleSignIn
    case needsDisplayName
    case needsJoinCrew
    case needsConnectStrava
    case ready
    case iCloudUnavailable
}

enum AppTab: Hashable {
    case crew
    case log
    case me
}

@MainActor
@Observable
final class AppSession {
    var phase: SessionPhase = .launching
    var profile: Profile?
    var team: Team?
    var suggestedName = ""
    var isBusy = false
    var bannerMessage: String?
    var selectedTab: AppTab = .crew

    let auth = AuthService()
    let avatars: AvatarCache
    let beerPhotos: BeerPhotoCache
    let cloudKit: CloudKitService
    let strava = StravaService()

    init() {
        let avatarCache = AvatarCache()
        let photoCache = BeerPhotoCache()
        avatars = avatarCache
        beerPhotos = photoCache
        cloudKit = CloudKitService(avatars: avatarCache, beerPhotos: photoCache)
    }

    func bootstrap() async {
        if LaunchEnvironment.isRunningUnitTests {
            phase = .needsAppleSignIn
            return
        }
        do {
            try await cloudKit.requireICloud()
            guard let userId = try auth.storedAppleUserId() else {
                phase = .needsAppleSignIn
                return
            }

            let state = await auth.credentialState(for: userId)
            guard state == .authorized else {
                try? auth.signOut()
                phase = .needsAppleSignIn
                return
            }

            if let existing = try await cloudKit.fetchProfile(appleUserId: userId) {
                profile = existing
                try await advance(from: existing)
            } else {
                phase = .needsDisplayName
            }
        } catch let error as BrickError where error == .iCloudUnavailable {
            phase = .iCloudUnavailable
        } catch {
            phase = .needsAppleSignIn
        }
    }

    func completeAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        isBusy = true
        defer { isBusy = false }
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                bannerMessage = BrickError.notSignedIn.localizedDescription
                return
            }
            do {
                try await cloudKit.requireICloud()
                try auth.persistAppleUserId(credential.user)
                let formatted = PersonNameComponentsFormatter().string(from: credential.fullName ?? PersonNameComponents())
                let trimmed = formatted.trimmingCharacters(in: .whitespacesAndNewlines)
                suggestedName = trimmed.isEmpty ? "" : trimmed

                if let existing = try await cloudKit.fetchProfile(appleUserId: credential.user) {
                    profile = existing
                    try await advance(from: existing)
                } else {
                    phase = .needsDisplayName
                }
            } catch let error as BrickError where error == .iCloudUnavailable {
                phase = .iCloudUnavailable
            } catch {
                bannerMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        case .failure(let error):
            bannerMessage = AuthService.userMessage(forSignInError: error)
        }
    }

    func saveDisplayName(_ rawName: String) async {
        isBusy = true
        defer { isBusy = false }

        do {
            let name = try DisplayName.validated(rawName)
            guard let userId = try auth.storedAppleUserId() else {
                throw BrickError.notSignedIn
            }
            var next = profile ?? Profile(
                id: Profile.recordName(forAppleUserId: userId),
                appleUserId: userId,
                displayName: name,
                teamId: "",
                stravaAthleteId: nil,
                stravaAthleteName: nil
            )
            next.displayName = name
            profile = try await cloudKit.saveProfile(next)
            try await advance(from: next)
        } catch {
            bannerMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// Updates the name on an existing profile without changing onboarding phase.
    func updateDisplayName(_ rawName: String) async throws {
        let name = try DisplayName.validated(rawName)
        guard var current = profile else { throw BrickError.missingProfile }
        if current.displayName == name { return }
        current.displayName = name
        profile = try await cloudKit.saveProfile(current)
    }

    func joinCrew(inviteCode rawCode: String) async {
        isBusy = true
        defer { isBusy = false }

        let code = InviteCode.normalized(rawCode)
        guard InviteCode.isValid(code) else {
            bannerMessage = BrickError.invalidInviteCode.localizedDescription
            return
        }

        do {
            guard var current = profile else { throw BrickError.missingProfile }
            let existing = try await cloudKit.fetchTeam(inviteCode: code)
            let team: Team
            if let existing {
                team = existing
            } else {
                team = try await cloudKit.saveTeam(
                    Team(
                        id: "team-\(code.lowercased())",
                        inviteCode: code,
                        name: AppConfig.defaultTeamName,
                        seasonStart: Date()
                    )
                )
            }
            current.teamId = team.id
            profile = try await cloudKit.saveProfile(current)
            self.team = team
            phase = current.isStravaConnected ? .ready : .needsConnectStrava
        } catch {
            bannerMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func connectStrava() async {
        isBusy = true
        defer { isBusy = false }
        do {
            guard var current = profile, team != nil else { throw BrickError.missingProfile }
            let credentials = try await strava.connect()
            current.stravaAthleteId = credentials.athleteId
            current.stravaAthleteName = credentials.athleteName
            profile = try await cloudKit.saveProfile(current)
            _ = try await syncStravaActivities()
            phase = .ready
        } catch let error as BrickError where error == .stravaDenied {
            bannerMessage = error.localizedDescription
        } catch {
            bannerMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func skipStrava() {
        phase = .ready
    }

    func disconnectStrava() async {
        do {
            try strava.disconnect()
            SyncCursor.clear()
            guard var current = profile else { return }
            current.stravaAthleteId = nil
            current.stravaAthleteName = nil
            profile = try await cloudKit.saveProfile(current)
        } catch {
            bannerMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    @discardableResult
    func syncStravaActivities() async throws -> Int {
        guard let profile, let team, profile.isStravaConnected else { return 0 }
        let after = SyncCursor.lastSyncAt() ?? team.seasonStart
        let dtos = try await strava.fetchActivities(after: after)
        let mapped = dtos.compactMap { ActivityMapper.map($0, userId: profile.id, teamId: team.id) }
        try await cloudKit.upsertActivities(mapped)
        SyncCursor.setLastSyncAt(Date())
        return mapped.count
    }

    func saveProfileAvatar(jpegData: Data) async throws {
        guard let current = profile else { throw BrickError.missingProfile }
        profile = try await cloudKit.saveProfileAvatar(current, jpegData: jpegData)
    }

    func removeProfileAvatar() async throws {
        guard let current = profile else { throw BrickError.missingProfile }
        profile = try await cloudKit.removeProfileAvatar(current)
    }

    func signOut() {
        PintReminderScheduler.cancel()
        try? auth.signOut()
        CrewCache.clear()
        SyncCursor.clear()
        avatars.removeAll()
        beerPhotos.removeAll()
        profile = nil
        team = nil
        suggestedName = ""
        selectedTab = .crew
        phase = .needsAppleSignIn
    }

    /// Recomputes the pint ping from CloudKit. Fetch failure leaves a pending request in place.
    func refreshPintReminderFromCloud() async {
        guard PintReminderSettings.isEnabled else { return }
        guard let profile, let team else { return }
        do {
            let beers = try await cloudKit.fetchBeers(userId: profile.id, teamId: team.id)
            let pint = StreakCalculator.summarize(
                activities: [],
                beers: beers,
                seasonStart: team.seasonStart
            ).pint
            await PintReminderScheduler.refresh(pint: pint)
        } catch {
            return
        }
    }

    /// Deletes CloudKit data for this user, then clears the local session.
    /// The Team record is left in place for remaining crew members.
    func deleteAccount() async {
        isBusy = true
        defer { isBusy = false }
        do {
            guard let current = profile else { throw BrickError.missingProfile }
            try await cloudKit.requireICloud()
            try await cloudKit.deleteAccountRecords(for: current)
            try? strava.disconnect()
            signOut()
        } catch let error as BrickError where error == .network || error == .iCloudUnavailable {
            bannerMessage = error.localizedDescription
        } catch {
            bannerMessage = BrickError.accountDeletionFailed.localizedDescription
        }
    }

    func clearBanner() {
        bannerMessage = nil
    }

    private func advance(from profile: Profile) async throws {
        if profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            phase = .needsDisplayName
            return
        }
        if profile.teamId.isEmpty {
            phase = .needsJoinCrew
            return
        }
        if let loaded = try await cloudKit.fetchTeam(recordName: profile.teamId) {
            team = loaded
        }
        phase = team == nil ? .needsJoinCrew : .ready
    }
}
