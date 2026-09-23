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
    private var loadGeneration = 0
    private var loadedTeamId: String?
    private var displayNames: [String: String] = [:]

    init(session: AppSession) {
        self.session = session
        if let snapshot = CrewCache.load() {
            state = snapshot.entries.isEmpty ? .empty : .loaded(snapshot.entries)
            staleMessage = "Updated \(Formatters.relative(snapshot.fetchedAt))"
        }
    }

    var ranked: [LeaderboardEntry] {
        ranked(for: board)
    }

    /// Rankings for a specific board so neighboring pages can render during a swipe.
    func ranked(for board: LeaderboardBoard) -> [LeaderboardEntry] {
        if case .loaded(let entries) = state {
            return LeaderboardBuilder.ranked(entries, board: board)
        }
        return []
    }

    var currentUserId: String? {
        session.profile?.id
    }

    func load(forceSync: Bool) async {
        loadGeneration += 1
        let generation = loadGeneration
        let incomingTeamId = session.team?.id
        let crewChanged = loadedTeamId != nil && loadedTeamId != incomingTeamId

        if crewChanged {
            // The previous crew's board is still on screen until this fetch returns.
            state = .loading
            pintFeed = .loading
            staleMessage = nil
            syncMessage = nil
            displayNames = [:]
        } else if hasLoadedOnce == false, case .loaded = state {
            staleMessage = staleMessage ?? "Showing last saved board"
        } else {
            state = .loading
        }
        hasLoadedOnce = true

        if forceSync, session.profile?.isStravaConnected == true {
            do {
                let count = try await session.syncStravaActivities()
                guard generation == loadGeneration else { return }
                if count > 0 {
                    syncMessage = count == 1 ? "Synced 1 activity" : "Synced \(count) activities"
                }
            } catch {
                guard generation == loadGeneration else { return }
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                if case .loaded = state {
                    staleMessage = message
                } else {
                    state = .failed(message)
                }
            }
        }

        guard generation == loadGeneration else { return }

        guard let team = session.team else {
            state = .failed(BrickError.missingProfile.localizedDescription)
            if case .loaded = pintFeed {
                return
            }
            pintFeed = .failed(BrickError.missingProfile.localizedDescription)
            return
        }

        if crewChanged == false {
            switch pintFeed {
            case .loaded, .empty:
                break
            default:
                pintFeed = .loading
            }
        }

        async let profilesTask = session.cloudKit.fetchProfiles(teamId: team.id)
        async let activitiesTask = session.cloudKit.fetchActivities(teamId: team.id, since: team.seasonStart)
        async let beersTask = session.cloudKit.fetchBeers(teamId: team.id, since: team.seasonStart)
        async let photosTask = session.cloudKit.fetchBeerPhotos(teamId: team.id, since: team.seasonStart)

        do {
            let profiles = try await profilesTask
            let activities = try await activitiesTask
            let beers = try await beersTask
            guard generation == loadGeneration else {
                _ = try? await photosTask
                return
            }
            displayNames = Dictionary(profiles.map { ($0.id, $0.displayName) }, uniquingKeysWith: { _, last in last })
            let entries = LeaderboardBuilder.build(
                profiles: profiles,
                activities: activities,
                beers: beers,
                seasonStart: team.seasonStart
            )
            let snapshot = CrewSnapshot(fetchedAt: Date(), seasonStart: team.seasonStart, entries: entries)
            CrewCache.save(snapshot)
            staleMessage = nil
            loadedTeamId = team.id
            state = entries.isEmpty ? .empty : .loaded(entries)
        } catch {
            guard generation == loadGeneration else {
                _ = try? await photosTask
                return
            }
            if case .loaded = state {
                staleMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            } else if crewChanged == false, let snapshot = CrewCache.load(), snapshot.entries.isEmpty == false {
                state = .loaded(snapshot.entries)
                staleMessage = "Couldn't refresh. Showing the last saved board."
            } else {
                state = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
            }
        }

        do {
            let photos = try await photosTask
            guard generation == loadGeneration else { return }
            pintFeed = photos.isEmpty ? .empty : .loaded(photos)
        } catch {
            guard generation == loadGeneration else { return }
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
