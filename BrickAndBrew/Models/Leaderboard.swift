import Foundation

struct LeaderboardEntry: Identifiable, Sendable, Codable, Hashable {
    let userId: String
    var displayName: String
    var swimMeters: Double
    var runMeters: Double
    var rideMeters: Double
    var beerCount: Int
    var streaks: StreakSet = .empty

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

    var trainingLoad: Double {
        swimPoints + runPoints + ridePoints
    }

    var coveredTrainingPoints: Double {
        Scoring.coveredTrainingPoints(beerCount: beerCount)
    }

    var uncoveredTrainingPoints: Double {
        Scoring.uncoveredTrainingPoints(trainingPoints: trainingLoad, beerCount: beerCount)
    }

    var uncoveredTrainingPenalty: Double {
        Scoring.uncoveredTrainingPenalty(trainingPoints: trainingLoad, beerCount: beerCount)
    }

    var grindTax: Double {
        Scoring.grindTax(trainingPoints: trainingLoad, beerCount: beerCount)
    }

    var totalIndex: Double {
        Scoring.totalIndex(
            swimMeters: swimMeters,
            runMeters: runMeters,
            rideMeters: rideMeters,
            beerCount: beerCount
        )
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
        seasonStart: Date,
        now: Date = Date(),
        calendar: Calendar = .current
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
                beerCount: myBeers.reduce(0) { $0 + $1.count },
                streaks: StreakCalculator.summarize(
                    activities: mine,
                    beers: myBeers,
                    seasonStart: seasonStart,
                    now: now,
                    calendar: calendar
                )
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

extension LeaderboardEntry {
    enum CodingKeys: String, CodingKey {
        case userId
        case displayName
        case swimMeters
        case runMeters
        case rideMeters
        case beerCount
        case streaks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = try container.decode(String.self, forKey: .userId)
        displayName = try container.decode(String.self, forKey: .displayName)
        swimMeters = try container.decode(Double.self, forKey: .swimMeters)
        runMeters = try container.decode(Double.self, forKey: .runMeters)
        rideMeters = try container.decode(Double.self, forKey: .rideMeters)
        beerCount = try container.decode(Int.self, forKey: .beerCount)
        // Older crew snapshots predate streaks; treat them as cold.
        streaks = try container.decodeIfPresent(StreakSet.self, forKey: .streaks) ?? .empty
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(swimMeters, forKey: .swimMeters)
        try container.encode(runMeters, forKey: .runMeters)
        try container.encode(rideMeters, forKey: .rideMeters)
        try container.encode(beerCount, forKey: .beerCount)
        try container.encode(streaks, forKey: .streaks)
    }
}
