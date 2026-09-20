import Foundation

/// Single place for the Total Index so boards stay consistent.
///
/// Sport boards still rank raw volume. The overall Index is the pub rule:
/// beers score hard, each pint covers a slice of training, and uncovered
/// kilometers take a grind tax so stacking swim / bike / run cannot buy the board.
enum Scoring: Sendable {
    static let swimPointsPerKilometer = 10.0
    static let runPointsPerKilometer = 3.0
    static let ridePointsPerKilometer = 1.0
    static let pointsPerBeer = 12.0
    static let metersPerKilometer = 1000.0

    /// Training points one beer covers at full value (2 km swim, ~6.7 km run, or 20 km bike).
    static let trainingPointsCoveredPerBeer = 20.0

    /// Extra tax on uncovered training, on top of dropping that volume from the Index.
    static let uncoveredTrainingPenaltyRate = 0.25

    static var uncoveredTrainingPenaltyPercent: Int {
        Int((uncoveredTrainingPenaltyRate * 100).rounded())
    }

    static func kilometers(fromMeters meters: Double) -> Double {
        meters / metersPerKilometer
    }

    static func trainingPoints(meters: Double, sport: SportKind) -> Double {
        let kilometers = kilometers(fromMeters: meters)
        switch sport {
        case .swim:
            return kilometers * swimPointsPerKilometer
        case .run:
            return kilometers * runPointsPerKilometer
        case .ride:
            return kilometers * ridePointsPerKilometer
        case .other:
            return 0
        }
    }

    static func beerPoints(count: Int) -> Double {
        Double(max(0, count)) * pointsPerBeer
    }

    /// Training load that beers fully cover. Extra volume is grind, not glory.
    static func coveredTrainingPoints(beerCount: Int) -> Double {
        Double(max(0, beerCount)) * trainingPointsCoveredPerBeer
    }

    /// Training points past pint coverage. Zero when beers cover the load.
    static func uncoveredTrainingPoints(trainingPoints: Double, beerCount: Int) -> Double {
        max(0, trainingPoints - coveredTrainingPoints(beerCount: beerCount))
    }

    /// Extra 25% hit on uncovered training, on top of stripping that volume.
    static func uncoveredTrainingPenalty(trainingPoints: Double, beerCount: Int) -> Double {
        uncoveredTrainingPoints(trainingPoints: trainingPoints, beerCount: beerCount) * uncoveredTrainingPenaltyRate
    }

    /// Uncovered training is removed from the Index, then taxed again.
    static func grindTax(trainingPoints: Double, beerCount: Int) -> Double {
        uncoveredTrainingPoints(trainingPoints: trainingPoints, beerCount: beerCount) * (1 + uncoveredTrainingPenaltyRate)
    }

    static func totalIndex(
        swimMeters: Double,
        runMeters: Double,
        rideMeters: Double,
        beerCount: Int
    ) -> Double {
        let training =
            trainingPoints(meters: swimMeters, sport: .swim)
            + trainingPoints(meters: runMeters, sport: .run)
            + trainingPoints(meters: rideMeters, sport: .ride)
        return training + beerPoints(count: beerCount) - grindTax(trainingPoints: training, beerCount: beerCount)
    }
}
