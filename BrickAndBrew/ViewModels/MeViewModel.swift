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
    var lastSyncText: String
    var bannerMessage: String?
    var streakState: LoadState<StreakSet> = .loading
    var isPintReminderEnabled: Bool = PintReminderSettings.isEnabled
    var isVenuePingEnabled: Bool = VenuePingSettings.isEnabled
    var isRequestingVenuePing = false
    var isSavingHome = false
    var isSavingWork = false
    var homeLabel: String?
    var workLabel: String?
    var homeError: String?
    var workError: String?
    var venueAuthorization: VenueAuthorization = .notDetermined
    var showsOpenSettings = false

    private let session: AppSession

    init(session: AppSession) {
        self.session = session
        if let last = SyncCursor.lastSyncAt() {
            lastSyncText = "Last Strava sync \(Formatters.relative(last))"
        } else {
            lastSyncText = "No Strava sync yet"
        }
        homeLabel = VenuePlaceStore.home.map { VenuePingCopy.placeLine(kind: .home, label: $0.label) }
        workLabel = VenuePlaceStore.work.map { VenuePingCopy.placeLine(kind: .work, label: $0.label) }
        venueAuthorization = VenueVisitMonitor.shared.authorization
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
            // Empty is "never logged this season." Zeros after a gap still get the three cards.
            let hasHistory = seasonBeers.isEmpty == false || mine.isEmpty == false
            streakState = hasHistory ? .loaded(set) : .empty
            await PintReminderScheduler.refresh(pint: set.pint)
        } catch {
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

    func setPintReminderEnabled(_ enabled: Bool) async {
        if enabled {
            let allowed = await PintReminderScheduler.requestAuthorization()
            if allowed == false {
                PintReminderSettings.isEnabled = false
                isPintReminderEnabled = false
                showsOpenSettings = true
                bannerMessage = StreakCopy.pintReminderDenied
                return
            }
            PintReminderSettings.isEnabled = true
            isPintReminderEnabled = true
            await PintReminderScheduler.refresh(pint: currentPint)
        } else {
            PintReminderSettings.isEnabled = false
            isPintReminderEnabled = false
            PintReminderScheduler.cancel()
        }
    }

    var venuePingStatusMessage: String? {
        guard isVenuePingEnabled else { return nil }
        switch venueAuthorization {
        case .ready, .notDetermined:
            return nil
        case .denied, .whenInUse:
            return VenuePingCopy.pausedAlways
        case .alwaysReduced:
            return VenuePingCopy.pausedPrecise
        }
    }

    func refreshVenueAuthorization() {
        venueAuthorization = VenueVisitMonitor.shared.authorization
        isVenuePingEnabled = VenuePingSettings.isEnabled
        homeLabel = VenuePlaceStore.home.map { VenuePingCopy.placeLine(kind: .home, label: $0.label) }
        workLabel = VenuePlaceStore.work.map { VenuePingCopy.placeLine(kind: .work, label: $0.label) }
        VenueVisitMonitor.shared.refreshMonitoring()
    }

    func setVenuePingEnabled(_ enabled: Bool) async {
        guard isRequestingVenuePing == false else { return }
        isRequestingVenuePing = true
        defer { isRequestingVenuePing = false }

        if enabled == false {
            VenuePingSettings.isEnabled = false
            isVenuePingEnabled = false
            VenueVisitMonitor.shared.refreshMonitoring()
            VenuePingScheduler.cancel()
            return
        }

        isVenuePingEnabled = true
        let notificationsAllowed = await VenuePingScheduler.requestAuthorization()
        if notificationsAllowed == false {
            denyVenuePing(message: VenuePingCopy.denied)
            return
        }

        let authorization = await VenueVisitMonitor.shared.requestAlwaysPrecise()
        venueAuthorization = authorization
        switch authorization {
        case .ready:
            VenuePingSettings.isEnabled = true
            isVenuePingEnabled = true
            VenueVisitMonitor.shared.refreshMonitoring()
        case .alwaysReduced:
            denyVenuePing(message: VenuePingCopy.needsPrecise)
        case .whenInUse, .notDetermined:
            denyVenuePing(message: VenuePingCopy.needsAlways)
        case .denied:
            denyVenuePing(message: VenuePingCopy.denied)
        }
    }

    func savePlace(_ kind: VenuePlaceKind) async {
        setSaving(true, kind: kind)
        setPlaceError(nil, kind: kind)
        defer { setSaving(false, kind: kind) }

        let authorization = await VenueVisitMonitor.shared.requestWhenInUse()
        venueAuthorization = authorization
        switch authorization {
        case .denied, .notDetermined:
            setPlaceError(VenuePingCopy.denied, kind: kind)
            showsOpenSettings = true
            bannerMessage = VenuePingCopy.denied
            return
        case .whenInUse, .alwaysReduced, .ready:
            break
        }

        do {
            let location = try await VenueVisitMonitor.shared.currentFix()
            let address = await VenuePlaceClassifier.addressLabel(for: location)
            let place = SavedPlace(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                label: address
            )
            VenuePlaceStore.setPlace(place, kind: kind)
            setPlaceLabel(VenuePingCopy.placeLine(kind: kind, label: address), kind: kind)
        } catch {
            setPlaceError(VenuePingCopy.fixFailed, kind: kind)
        }
    }

    func clearPlace(_ kind: VenuePlaceKind) {
        VenuePlaceStore.setPlace(nil, kind: kind)
        setPlaceLabel(nil, kind: kind)
        setPlaceError(nil, kind: kind)
    }

    private func denyVenuePing(message: String) {
        VenuePingSettings.isEnabled = false
        isVenuePingEnabled = false
        VenueVisitMonitor.shared.refreshMonitoring()
        showsOpenSettings = true
        bannerMessage = message
    }

    private func setSaving(_ saving: Bool, kind: VenuePlaceKind) {
        switch kind {
        case .home: isSavingHome = saving
        case .work: isSavingWork = saving
        }
    }

    private func setPlaceLabel(_ label: String?, kind: VenuePlaceKind) {
        switch kind {
        case .home: homeLabel = label
        case .work: workLabel = label
        }
    }

    private func setPlaceError(_ message: String?, kind: VenuePlaceKind) {
        switch kind {
        case .home: homeError = message
        case .work: workError = message
        }
    }

    private var currentPint: Streak {
        if case .loaded(let set) = streakState {
            return set.pint
        }
        return .empty
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
