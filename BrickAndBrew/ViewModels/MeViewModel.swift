import Foundation

@MainActor
@Observable
final class MeViewModel {
    var isSyncing = false
    var isDeletingAccount = false
    var lastSyncText: String
    var bannerMessage: String?

    private let session: AppSession

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

    var inviteCode: String {
        session.team?.inviteCode ?? "—"
    }

    var stravaName: String? {
        session.profile?.stravaAthleteName
    }

    var isStravaConnected: Bool {
        session.profile?.isStravaConnected == true
    }

    func syncNow() async {
        guard isSyncing == false else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let count = try await session.syncStravaActivities()
            lastSyncText = "Last Strava sync \(Formatters.relative(Date()))"
            bannerMessage = count == 0
                ? "You're up to date. No new activities."
                : (count == 1 ? "Synced 1 activity." : "Synced \(count) activities.")
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
    }

    func disconnectStrava() async {
        await session.disconnectStrava()
        lastSyncText = "No Strava sync yet"
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
}
