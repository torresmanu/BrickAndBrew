import Foundation

/// Side-game streaks. Not Index points. Recomputed from beer and activity timestamps.
enum StreakKind: String, Codable, Sendable, CaseIterable, Identifiable {
    case pint
    case brick
    case brickAndBrew

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pint: "Pint"
        case .brick: "Brick"
        case .brickAndBrew: "Brick & Brew"
        }
    }
}

struct Streak: Sendable, Codable, Hashable {
    var current: Int
    var longest: Int
    var lastQualifyingDay: Date?

    static let empty = Streak(current: 0, longest: 0, lastQualifyingDay: nil)

    /// Alive from yesterday, but today is still empty — tease, don't break.
    func isAtRisk(now: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard current > 0, let lastQualifyingDay else { return false }
        let today = calendar.startOfDay(for: now)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return false }
        let lastDay = calendar.startOfDay(for: lastQualifyingDay)
        return calendar.isDate(lastDay, inSameDayAs: yesterday)
    }
}

struct StreakSet: Sendable, Codable, Hashable {
    var pint: Streak
    var brick: Streak
    var brickAndBrew: Streak

    static let empty = StreakSet(pint: .empty, brick: .empty, brickAndBrew: .empty)

    func streak(for kind: StreakKind) -> Streak {
        switch kind {
        case .pint: pint
        case .brick: brick
        case .brickAndBrew: brickAndBrew
        }
    }

    func streak(for board: LeaderboardBoard) -> Streak {
        streak(for: board.streakKind)
    }
}

enum StreakCalculator: Sendable {
    static let minimumSwimMeters = 200.0
    static let minimumRunMeters = 1_000.0
    static let minimumRideMeters = 5_000.0
    /// Short GPS files still count if they actually took time.
    static let minimumMovingTimeSeconds = 10 * 60

    static func summarize(
        activities: [Activity],
        beers: [Beer],
        seasonStart: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> StreakSet {
        let pintDays = qualifyingDays(
            beers: beers,
            seasonStart: seasonStart,
            calendar: calendar
        )
        let brickDays = qualifyingDays(
            activities: activities,
            seasonStart: seasonStart,
            calendar: calendar
        )
        let comboDays = pintDays.intersection(brickDays)

        return StreakSet(
            pint: streak(from: pintDays, now: now, calendar: calendar),
            brick: streak(from: brickDays, now: now, calendar: calendar),
            brickAndBrew: streak(from: comboDays, now: now, calendar: calendar)
        )
    }

    static func qualifies(_ activity: Activity) -> Bool {
        switch activity.sport {
        case .other:
            return false
        case .swim, .run, .ride:
            if activity.movingTimeSeconds >= minimumMovingTimeSeconds {
                return true
            }
            return activity.distanceMeters >= minimumDistanceMeters(for: activity.sport)
        }
    }

    static func minimumDistanceMeters(for sport: SportKind) -> Double {
        switch sport {
        case .swim: minimumSwimMeters
        case .run: minimumRunMeters
        case .ride: minimumRideMeters
        case .other: .infinity
        }
    }

    private static func qualifyingDays(
        beers: [Beer],
        seasonStart: Date,
        calendar: Calendar
    ) -> Set<Date> {
        Set(
            beers.compactMap { beer in
                guard beer.count >= 1, beer.loggedAt >= seasonStart else { return nil }
                return calendar.startOfDay(for: beer.loggedAt)
            }
        )
    }

    private static func qualifyingDays(
        activities: [Activity],
        seasonStart: Date,
        calendar: Calendar
    ) -> Set<Date> {
        Set(
            activities.compactMap { activity in
                guard activity.startDate >= seasonStart, qualifies(activity) else { return nil }
                return calendar.startOfDay(for: activity.startDate)
            }
        )
    }

    /// Current run ends today or yesterday. Longest is the best consecutive run this season.
    private static func streak(from days: Set<Date>, now: Date, calendar: Calendar) -> Streak {
        let today = calendar.startOfDay(for: now)
        let lastQualifyingDay = days.max()
        let current = currentLength(days: days, today: today, calendar: calendar)
        let longest = longestLength(days: days, calendar: calendar)
        return Streak(
            current: current,
            longest: longest,
            lastQualifyingDay: lastQualifyingDay
        )
    }

    private static func currentLength(days: Set<Date>, today: Date, calendar: Calendar) -> Int {
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today).map({ calendar.startOfDay(for: $0) }) else {
            return 0
        }

        let start: Date
        if days.contains(today) {
            start = today
        } else if days.contains(yesterday) {
            start = yesterday
        } else {
            return 0
        }

        var length = 0
        var cursor = start
        while days.contains(cursor) {
            length += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = calendar.startOfDay(for: previous)
        }
        return length
    }

    private static func longestLength(days: Set<Date>, calendar: Calendar) -> Int {
        let chronological = days.sorted()
        guard chronological.isEmpty == false else { return 0 }

        var longest = 1
        var run = 1
        for index in 1..<chronological.count {
            let previous = chronological[index - 1]
            let day = chronological[index]
            if let next = calendar.date(byAdding: .day, value: 1, to: previous),
               calendar.isDate(day, inSameDayAs: next) {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
        }
        return longest
    }
}

extension LeaderboardBoard {
    /// Which streak the crew-row badge should show for this board.
    var streakKind: StreakKind {
        switch self {
        case .overall: .brickAndBrew
        case .beers: .pint
        case .swim, .ride, .run: .brick
        }
    }
}
