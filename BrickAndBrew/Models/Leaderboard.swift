import Foundation

struct LeaderboardEntry: Identifiable, Sendable, Codable, Hashable {
    let userId: String
    var displayName: String
    var swimMeters: Double
    var runMeters: Double
    var rideMeters: Double
    var beerCount: Int

    var id: String { userId }

    var swimPoints: Double {
        Scoring.trainingPoints(meters: swimMeters, sport: .swim)
    }

    var runPoints: Double {
        Scoring.trainingPoints(meters: runMeters, sport: .run)
    }

    var ridePoints: Double {
        Scoring.trainingPoints(meters: rideMeters, sport: .ride)
    }

    var beerPoints: Double {
        Scoring.beerPoints(count: beerCount)
    }

    var totalIndex: Double {
        swimPoints + runPoints + ridePoints + beerPoints
    }

    func points(for board: LeaderboardBoard) -> Double {
        switch board {
        case .overall: totalIndex
        case .swim: swimPoints
        case .run: runPoints
        case .ride: ridePoints
        case .beers: beerPoints
        }
    }

    func detail(for board: LeaderboardBoard) -> String {
        switch board {
        case .overall:
            Formatters.points(totalIndex)
        case .swim:
            Formatters.kilometers(swimMeters)
        case .run:
            Formatters.kilometers(runMeters)
        case .ride:
            Formatters.kilometers(rideMeters)
        case .beers:
            Formatters.beerCount(beerCount)
        }
    }
}

enum LeaderboardBoard: String, CaseIterable, Identifiable, Sendable {
    case overall
    case swim
    case ride
    case run
    case beers

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overall: "Index"
        case .swim: "Swim"
        case .ride: "Bike"
        case .run: "Run"
        case .beers: "Beers"
        }
    }
}

struct CrewSnapshot: Sendable, Codable {
    var fetchedAt: Date
    var seasonStart: Date
    var entries: [LeaderboardEntry]
}

enum LeaderboardBuilder {
    static func build(
        profiles: [Profile],
        activities: [Activity],
        beers: [Beer],
        seasonStart: Date
    ) -> [LeaderboardEntry] {
        let scoredActivities = activities.filter { $0.startDate >= seasonStart }
        let scoredBeers = beers.filter { $0.loggedAt >= seasonStart }

        return profiles.map { profile in
            let mine = scoredActivities.filter { $0.userId == profile.id }
            let myBeers = scoredBeers.filter { $0.userId == profile.id }
            return LeaderboardEntry(
                userId: profile.id,
                displayName: profile.displayName,
                swimMeters: mine.filter { $0.sport == .swim }.reduce(0) { $0 + $1.distanceMeters },
                runMeters: mine.filter { $0.sport == .run }.reduce(0) { $0 + $1.distanceMeters },
                rideMeters: mine.filter { $0.sport == .ride }.reduce(0) { $0 + $1.distanceMeters },
                beerCount: myBeers.reduce(0) { $0 + $1.count }
            )
        }
        .sorted { lhs, rhs in
            if lhs.totalIndex == rhs.totalIndex {
                return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
            }
            return lhs.totalIndex > rhs.totalIndex
        }
    }

    static func ranked(_ entries: [LeaderboardEntry], board: LeaderboardBoard) -> [LeaderboardEntry] {
        entries.sorted { lhs, rhs in
            let left = lhs.points(for: board)
            let right = rhs.points(for: board)
            if left == right {
                return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
            }
            return left > right
        }
    }
}
