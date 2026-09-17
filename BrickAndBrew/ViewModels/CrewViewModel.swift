import Foundation

@MainActor
@Observable
final class CrewViewModel {
    var board: LeaderboardBoard = .overall
    var state: LoadState<[LeaderboardEntry]> = .loading
    var staleMessage: String?
    var syncMessage: String?

    private let session: AppSession
    private var hasLoadedOnce = false

    init(session: AppSession) {
        self.session = session
        if let snapshot = CrewCache.load() {
            state = snapshot.entries.isEmpty ? .empty : .loaded(snapshot.entries)
            staleMessage = "Updated \(Formatters.relative(snapshot.fetchedAt))"
        }
    }

    var ranked: [LeaderboardEntry] {
        if case .loaded(let entries) = state {
            return LeaderboardBuilder.ranked(entries, board: board)
        }
        return []
    }

    var currentUserId: String? {
        session.profile?.id
    }

    func load(forceSync: Bool) async {
        if hasLoadedOnce == false, case .loaded = state {
            staleMessage = staleMessage ?? "Showing last saved board"
        } else {
            state = .loading
        }
        hasLoadedOnce = true

        do {
            if forceSync, session.profile?.isStravaConnected == true {
                let count = try await session.syncStravaActivities()
                if count > 0 {
                    syncMessage = count == 1 ? "Synced 1 activity" : "Synced \(count) activities"
                }
            }

            guard let team = session.team else {
                state = .failed(BrickError.missingProfile.localizedDescription)
                return
            }

            async let profiles = session.cloudKit.fetchProfiles(teamId: team.id)
            async let activities = session.cloudKit.fetchActivities(teamId: team.id, since: team.seasonStart)
            async let beers = session.cloudKit.fetchBeers(teamId: team.id, since: team.seasonStart)
            let entries = LeaderboardBuilder.build(
                profiles: try await profiles,
                activities: try await activities,
                beers: try await beers,
                seasonStart: team.seasonStart
            )
            let snapshot = CrewSnapshot(fetchedAt: Date(), seasonStart: team.seasonStart, entries: entries)
            CrewCache.save(snapshot)
            staleMessage = nil
            state = entries.isEmpty ? .empty : .loaded(entries)
        } catch {
            if case .loaded = state {
                staleMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            } else if let snapshot = CrewCache.load(), snapshot.entries.isEmpty == false {
                state = .loaded(snapshot.entries)
                staleMessage = "Couldn't refresh. Showing the last saved board."
            } else {
                state = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
            }
        }
    }

    func selectBoard(_ board: LeaderboardBoard) {
        self.board = board
    }

    func retry() async {
        await load(forceSync: true)
    }
}
