import Foundation

/// Receipt for one board score: where the points came from, and what the grind tax took.
struct ScoreBreakdown: Sendable, Hashable {
    struct Line: Identifiable, Sendable, Hashable {
        enum Kind: Sendable, Hashable {
            case training
            case beers
            case uncovered
            case tax
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
            "No swim, bike, run, or beers this season yet. The Index stays at zero until a brick or a pint lands."
        case .swim:
            "No swim volume this season yet."
        case .run:
            "No run volume this season yet."
        case .ride:
            "No bike volume this season yet."
        case .beers:
            "No beers logged this season yet."
        }
    }

    static func make(
        swimMeters: Double,
        runMeters: Double,
        rideMeters: Double,
        beerCount: Int,
        board: LeaderboardBoard
    ) -> ScoreBreakdown {
        switch board {
        case .overall:
            overall(
                swimMeters: swimMeters,
                runMeters: runMeters,
                rideMeters: rideMeters,
                beerCount: beerCount
            )
        case .swim:
            sport(meters: swimMeters, sport: .swim, board: .swim)
        case .run:
            sport(meters: runMeters, sport: .run, board: .run)
        case .ride:
            sport(meters: rideMeters, sport: .ride, board: .ride)
        case .beers:
            beers(count: beerCount)
        }
    }
}

private extension ScoreBreakdown {
    static func overall(
        swimMeters: Double,
        runMeters: Double,
        rideMeters: Double,
        beerCount: Int
    ) -> ScoreBreakdown {
        let swim = Scoring.trainingPoints(meters: swimMeters, sport: .swim)
        let run = Scoring.trainingPoints(meters: runMeters, sport: .run)
        let ride = Scoring.trainingPoints(meters: rideMeters, sport: .ride)
        let training = swim + run + ride
        let beerPoints = Scoring.beerPoints(count: beerCount)
        let uncovered = Scoring.uncoveredTrainingPoints(trainingPoints: training, beerCount: beerCount)
        let tax = Scoring.grindTaxSurcharge(trainingPoints: training, beerCount: beerCount)

        var lines: [Line] = []
        appendTraining(&lines, title: "Swim", meters: swimMeters, points: swim, id: "swim")
        appendTraining(&lines, title: "Bike", meters: rideMeters, points: ride, id: "ride")
        appendTraining(&lines, title: "Run", meters: runMeters, points: run, id: "run")
        if beerCount > 0 {
            lines.append(
                Line(
                    id: "beers",
                    title: "Beers",
                    detail: Formatters.beerCount(beerCount),
                    points: beerPoints,
                    kind: .beers
                )
            )
        }
        // Uncovered volume is dropped first, then the 25% surcharge lands as grind tax.
        if uncovered > 0 {
            lines.append(
                Line(
                    id: "uncovered",
                    title: "Uncovered training",
                    detail: "Beyond pint coverage",
                    points: -uncovered,
                    kind: .uncovered
                )
            )
        }
        if tax > 0 {
            lines.append(
                Line(
                    id: "tax",
                    title: "Grind tax",
                    detail: "\(Scoring.uncoveredTrainingPenaltyPercent)% on uncovered points",
                    points: -tax,
                    kind: .tax
                )
            )
        }

        return ScoreBreakdown(
            board: .overall,
            total: Scoring.totalIndex(
                swimMeters: swimMeters,
                runMeters: runMeters,
                rideMeters: rideMeters,
                beerCount: beerCount
            ),
            lines: lines,
            footnote: overallFootnote(
                training: training,
                beerCount: beerCount,
                uncovered: uncovered
            )
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
            footnote: "\(weight) points per km. The grind tax only hits the Index."
        )
    }

    static func beers(count: Int) -> ScoreBreakdown {
        let points = Scoring.beerPoints(count: count)
        let lines: [Line]
        if count > 0 {
            lines = [
                Line(
                    id: "beers",
                    title: "Beers",
                    detail: Formatters.beerCount(count),
                    points: points,
                    kind: .beers
                )
            ]
        } else {
            lines = []
        }
        return ScoreBreakdown(
            board: .beers,
            total: points,
            lines: lines,
            footnote: "\(Formatters.compactNumber(Scoring.pointsPerBeer)) points each. The grind tax only hits the Index."
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

    static func overallFootnote(training: Double, beerCount: Int, uncovered: Double) -> String {
        if training <= 0, beerCount <= 0 {
            return "No swim, bike, run, or beers this season yet. The Index stays at zero until a brick or a pint lands."
        }
        if uncovered > 0 {
            let dropped = Formatters.compactNumber(uncovered)
            let tax = "\(Scoring.uncoveredTrainingPenaltyPercent)%"
            if beerCount <= 0 {
                return "No pints this season, so \(dropped) training points left the Index and took a \(tax) tax."
            }
            let covered = Formatters.compactNumber(Scoring.trainingPointsCoveredPerBeer)
            let pints = Formatters.beerCount(beerCount)
            return "Each pint covers \(covered) training points. \(dropped) went uncovered by \(pints), left the Index, and took a \(tax) tax."
        }
        if training > 0 {
            return "Pints cover the training load. No grind tax."
        }
        return "No bricks this season, so nothing to tax."
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
