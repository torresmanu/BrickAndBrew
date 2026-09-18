import Foundation

@MainActor
@Observable
final class CrewViewModel {
    var board: LeaderboardBoard = .overall
    var state: LoadState<[LeaderboardEntry]> = .loading
    var pintFeed: LoadState<[BeerPhoto]> = .loading
    var staleMessage: String?
    var syncMessage: String?

    private let session: AppSession
    private var hasLoadedOnce = false
    private var displayNames: [String: String] = [:]

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

        if forceSync, session.profile?.isStravaConnected == true {
            do {
                let count = try await session.syncStravaActivities()
                if count > 0 {
                    syncMessage = count == 1 ? "Synced 1 activity" : "Synced \(count) activities"
                }
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                if case .loaded = state {
                    staleMessage = message
                } else {
                    state = .failed(message)
                }
            }
        }

        guard let team = session.team else {
            state = .failed(BrickError.missingProfile.localizedDescription)
            if case .loaded = pintFeed {
                return
            }
            pintFeed = .failed(BrickError.missingProfile.localizedDescription)
            return
        }

        switch pintFeed {
        case .loaded, .empty:
            break
        default:
            pintFeed = .loading
        }

        async let profilesTask = session.cloudKit.fetchProfiles(teamId: team.id)
        async let activitiesTask = session.cloudKit.fetchActivities(teamId: team.id, since: team.seasonStart)
        async let beersTask = session.cloudKit.fetchBeers(teamId: team.id, since: team.seasonStart)
        async let photosTask = session.cloudKit.fetchBeerPhotos(teamId: team.id, since: team.seasonStart)

        do {
            let profiles = try await profilesTask
                displayNames = Dictionary(profiles.map { ($0.id, $0.displayName) }, uniquingKeysWith: { _, last in last })
            let entries = LeaderboardBuilder.build(
                profiles: profiles,
                activities: try await activitiesTask,
                beers: try await beersTask,
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

        do {
            let photos = try await photosTask
            pintFeed = photos.isEmpty ? .empty : .loaded(photos)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            switch pintFeed {
            case .loaded, .empty:
                break
            default:
                pintFeed = .failed(message)
            }
        }
    }

    func displayName(for userId: String) -> String {
        displayNames[userId] ?? "Teammate"
    }

    func retryPintFeed() async {
        guard let team = session.team else { return }
        switch pintFeed {
        case .loaded, .empty:
            break
        default:
            pintFeed = .loading
        }
        do {
            let photos = try await session.cloudKit.fetchBeerPhotos(teamId: team.id, since: team.seasonStart)
            pintFeed = photos.isEmpty ? .empty : .loaded(photos)
        } catch {
            pintFeed = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }

    func selectBoard(_ board: LeaderboardBoard) {
        self.board = board
    }

    func retry() async {
        await load(forceSync: true)
    }

    func applyDisplayName(_ name: String, userId: String) {
        displayNames[userId] = name
        guard case .loaded(let entries) = state else {
            CrewCache.updateDisplayName(userId: userId, displayName: name)
            return
        }
        let updated = entries.map { entry -> LeaderboardEntry in
            guard entry.userId == userId else { return entry }
            var next = entry
            next.displayName = name
            return next
        }
        state = .loaded(updated)
        if var snapshot = CrewCache.load() {
            snapshot.entries = updated
            CrewCache.save(snapshot)
        }
    }
}
