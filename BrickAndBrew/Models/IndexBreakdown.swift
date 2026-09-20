import Foundation

/// Line-by-line Index math for one crew member, using the same Scoring constants as the board.
struct IndexBreakdown: Sendable, Equatable {
    struct Line: Identifiable, Sendable, Equatable {
        enum Kind: String, Sendable {
            case swim
            case ride
            case run
            case beers
            case uncovered
            case grindTax
        }

        let kind: Kind
        let title: String
        let source: String
        let points: Double

        var id: String { kind.rawValue }

        /// Uncovered volume and the extra tax are subtracted from the Index.
        var isPenalty: Bool {
            switch kind {
            case .uncovered, .grindTax:
                true
            case .swim, .ride, .run, .beers:
                false
            }
        }
    }

    let displayName: String
    let isCurrentUser: Bool
    let total: Double
    let beerCount: Int
    let coveredTrainingPoints: Double
    let uncoveredTrainingPoints: Double
    let lines: [Line]

    /// Anything that can put a number on the Index this season.
    var hasVolume: Bool {
        beerCount > 0 || lines.contains { line in
            switch line.kind {
            case .swim, .ride, .run:
                true
            case .beers, .uncovered, .grindTax:
                false
            }
        }
    }

    init(entry: LeaderboardEntry, isCurrentUser: Bool) {
        displayName = entry.displayName
        self.isCurrentUser = isCurrentUser
        total = entry.totalIndex
        beerCount = entry.beerCount
        coveredTrainingPoints = entry.coveredTrainingPoints
        uncoveredTrainingPoints = entry.uncoveredTrainingPoints
        lines = Self.lines(for: entry)
    }

    /// Spoken summary, e.g. "50 pts because of your bike and 24 pts because of your 2 beers".
    var explanation: String {
        guard hasVolume else {
            if isCurrentUser {
                return "No swim, bike, run, or beers this season yet."
            }
            return "\(displayName) has no swim, bike, run, or beers this season yet."
        }

        let credits = lines.compactMap { line -> String? in
            guard line.isPenalty == false else { return nil }
            // Zero beers still show as a row in the math, but they read poorly in the sentence.
            if line.kind == .beers && beerCount == 0 {
                return nil
            }
            return creditClause(for: line)
        }

        var parts = credits
        if let tax = lines.first(where: { $0.kind == .grindTax }) {
            parts.append(taxClause(points: tax.points))
        }

        var sentence = Self.capitalizedSentence(Self.joined(parts)) + "."
        if uncoveredTrainingPoints == 0, hasTrainingCredit {
            sentence += " Pints cover all of this training, so there's no grind tax."
        }
        return sentence
    }

    var headline: String {
        let index = Formatters.points(total)
        if isCurrentUser {
            return "Your Index is \(index)"
        }
        return "\(displayName)'s Index is \(index)"
    }

    /// Short rule reminder when uncovered training actually hit the number.
    var taxNote: String? {
        guard uncoveredTrainingPoints > 0 else { return nil }
        let percent = Scoring.uncoveredTrainingPenaltyPercent
        if beerCount == 0 {
            return "No pints means none of this training is covered. Uncovered kilometers are stripped from the Index, then taxed another \(percent)%."
        }
        let covered = Formatters.compactNumber(Scoring.trainingPointsCoveredPerBeer)
        return "Each beer covers \(covered) training points. Uncovered kilometers are stripped from the Index, then taxed another \(percent)%."
    }

    private var possessive: String {
        isCurrentUser ? "your" : "\(displayName)'s"
    }

    private var hasTrainingCredit: Bool {
        lines.contains { line in
            switch line.kind {
            case .swim, .ride, .run:
                true
            case .beers, .uncovered, .grindTax:
                false
            }
        }
    }

    private func creditClause(for line: Line) -> String {
        let points = Formatters.points(line.points)
        switch line.kind {
        case .swim, .ride, .run:
            return "\(points) because of \(possessive) \(line.title.lowercased()) (\(line.source))"
        case .beers:
            return "\(points) because of \(possessive) \(Formatters.beerCount(beerCount))"
        case .uncovered, .grindTax:
            return points
        }
    }

    private func taxClause(points: Double) -> String {
        let tax = Formatters.signedPoints(points)
        let actor = isCurrentUser ? "you had" : "\(displayName) had"
        let reason: String
        if beerCount == 0 {
            reason = "none of this training is covered by pints"
        } else {
            reason = "\(Formatters.compactNumber(uncoveredTrainingPoints)) training pts weren't covered by pints"
        }
        return "\(actor) a grind tax of \(tax) because \(reason)"
    }

    /// Credits first, then strip uncovered volume, then the extra 25% tax so the rows sum to the Index.
    private static func lines(for entry: LeaderboardEntry) -> [Line] {
        var lines: [Line] = []

        if entry.swimMeters > 0 {
            lines.append(
                Line(
                    kind: .swim,
                    title: SportKind.swim.title,
                    source: Formatters.kilometers(entry.swimMeters),
                    points: entry.swimPoints
                )
            )
        }
        if entry.rideMeters > 0 {
            lines.append(
                Line(
                    kind: .ride,
                    title: SportKind.ride.title,
                    source: Formatters.kilometers(entry.rideMeters),
                    points: entry.ridePoints
                )
            )
        }
        if entry.runMeters > 0 {
            lines.append(
                Line(
                    kind: .run,
                    title: SportKind.run.title,
                    source: Formatters.kilometers(entry.runMeters),
                    points: entry.runPoints
                )
            )
        }

        let hasTraining = entry.swimMeters > 0 || entry.rideMeters > 0 || entry.runMeters > 0
        if entry.beerCount > 0 || hasTraining {
            lines.append(
                Line(
                    kind: .beers,
                    title: "Beers",
                    source: Formatters.beerCount(entry.beerCount),
                    points: entry.beerPoints
                )
            )
        }

        if entry.uncoveredTrainingPoints > 0 {
            lines.append(
                Line(
                    kind: .uncovered,
                    title: "Uncovered training",
                    source: "\(Formatters.compactNumber(entry.uncoveredTrainingPoints)) pts past pint coverage",
                    points: -entry.uncoveredTrainingPoints
                )
            )
            lines.append(
                Line(
                    kind: .grindTax,
                    title: "Grind tax",
                    source: "\(Scoring.uncoveredTrainingPenaltyPercent)% of uncovered training",
                    points: -entry.uncoveredTrainingPenalty
                )
            )
        }

        return lines
    }

    static func joined(_ parts: [String]) -> String {
        guard let last = parts.last else { return "" }
        if parts.count == 1 {
            return last
        }
        if parts.count == 2 {
            return "\(parts[0]) and \(parts[1])"
        }
        let head = parts.dropLast().joined(separator: ", ")
        return "\(head), and \(last)"
    }

    static func capitalizedSentence(_ text: String) -> String {
        guard let first = text.first else { return text }
        return String(first).uppercased() + text.dropFirst()
    }
}

/// Payload for the Index breakdown sheet. Rank is frozen at tap time so switching boards cannot rewrite it.
struct IndexBreakdownSelection: Identifiable, Hashable {
    let entry: LeaderboardEntry
    let rank: Int
    var id: String { entry.userId }
}
