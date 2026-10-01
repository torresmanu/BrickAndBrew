import Foundation

/// Receipt for one board score.
struct ScoreBreakdown: Sendable, Hashable {
    struct Line: Identifiable, Sendable, Hashable {
        enum Kind: Sendable, Hashable {
            case training
            case beers
        }

        let id: String
        let title: String
        let detail: String
        let points: Double
        let kind: Kind
    }

    let board: LeaderboardBoard
    let total: Double
    let lines: [Line]
    let footnote: String

    var isEmpty: Bool {
        lines.isEmpty
    }

    var emptyMessage: String {
        switch board {
        case .overall:
            "No swim, bike, or run this season yet. The Index stays at zero until a session lands."
        case .swim:
            "No swim volume this season yet."
        case .run:
            "No run volume this season yet."
        case .ride:
            "No bike volume this season yet."
        }
    }

    static func make(
        swimMeters: Double,
        runMeters: Double,
        rideMeters: Double,
        scoredPintDays: Int,
        board: LeaderboardBoard
    ) -> ScoreBreakdown {
        switch board {
        case .overall:
            overall(
                swimMeters: swimMeters,
                runMeters: runMeters,
                rideMeters: rideMeters,
                scoredPintDays: scoredPintDays
            )
        case .swim:
            sport(meters: swimMeters, sport: .swim, board: .swim)
        case .run:
            sport(meters: runMeters, sport: .run, board: .run)
        case .ride:
            sport(meters: rideMeters, sport: .ride, board: .ride)
        }
    }
}

private extension ScoreBreakdown {
    static func overall(
        swimMeters: Double,
        runMeters: Double,
        rideMeters: Double,
        scoredPintDays: Int
    ) -> ScoreBreakdown {
        let swim = Scoring.trainingPoints(meters: swimMeters, sport: .swim)
        let run = Scoring.trainingPoints(meters: runMeters, sport: .run)
        let ride = Scoring.trainingPoints(meters: rideMeters, sport: .ride)
        let training = swim + run + ride
        let pintPoints = Scoring.beerPoints(scoredPintDays: scoredPintDays)

        var lines: [Line] = []
        appendTraining(&lines, title: "Swim", meters: swimMeters, points: swim, id: "swim")
        appendTraining(&lines, title: "Bike", meters: rideMeters, points: ride, id: "ride")
        appendTraining(&lines, title: "Run", meters: runMeters, points: run, id: "run")
        if scoredPintDays > 0 {
            lines.append(
                Line(
                    id: "pints",
                    title: "Pint after training",
                    detail: scoredPintDays == 1 ? "1 day" : "\(scoredPintDays) days",
                    points: pintPoints,
                    kind: .beers
                )
            )
        }

        return ScoreBreakdown(
            board: .overall,
            total: Scoring.totalIndex(
                swimMeters: swimMeters,
                runMeters: runMeters,
                rideMeters: rideMeters,
                scoredPintDays: scoredPintDays
            ),
            lines: lines,
            footnote: overallFootnote(training: training, scoredPintDays: scoredPintDays)
        )
    }

    static func sport(meters: Double, sport: SportKind, board: LeaderboardBoard) -> ScoreBreakdown {
        let points = Scoring.trainingPoints(meters: meters, sport: sport)
        let weight = Formatters.compactNumber(weightPerKilometer(for: sport))
        let lines: [Line]
        if meters > 0 {
            lines = [
                Line(
                    id: board.rawValue,
                    title: board.title,
                    detail: Formatters.kilometers(meters),
                    points: points,
                    kind: .training
                )
            ]
        } else {
            lines = []
        }
        return ScoreBreakdown(
            board: board,
            total: points,
            lines: lines,
            footnote: "\(weight) points per km."
        )
    }

    static func appendTraining(
        _ lines: inout [Line],
        title: String,
        meters: Double,
        points: Double,
        id: String
    ) {
        guard meters > 0 else { return }
        lines.append(
            Line(
                id: id,
                title: title,
                detail: Formatters.kilometers(meters),
                points: points,
                kind: .training
            )
        )
    }

    static func overallFootnote(training: Double, scoredPintDays: Int) -> String {
        let bonus = Formatters.compactNumber(Scoring.pointsPerScoredPint)
        if training <= 0, scoredPintDays <= 0 {
            return "No swim, bike, or run this season yet. The Index stays at zero until a session lands."
        }
        if scoredPintDays > 0 {
            return "Training always scores. One pint on a day you also train adds \(bonus) points. Extra pints that day add nothing, and skipping a pint does not lower the Index."
        }
        return "Training always scores. A pint is optional: one on a day you also train adds \(bonus) points. Skipping it does not lower the Index."
    }

    static func weightPerKilometer(for sport: SportKind) -> Double {
        switch sport {
        case .swim: Scoring.swimPointsPerKilometer
        case .run: Scoring.runPointsPerKilometer
        case .ride: Scoring.ridePointsPerKilometer
        case .other: 0
        }
    }
}
