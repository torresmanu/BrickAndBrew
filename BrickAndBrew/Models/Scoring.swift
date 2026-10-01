import Foundation

/// Single place for the Total Index so boards stay consistent.
///
/// Sport boards rank training volume. The Index is that same training, plus at most
/// one pint on a day that also has a qualifying brick. Extra pints add nothing.
/// A day with no pint does not reduce the score.
enum Scoring: Sendable {
    static let swimPointsPerKilometer = 26.0
    static let runPointsPerKilometer = 4.0
    static let ridePointsPerKilometer = 1.0
    /// Flat bonus for one pint on a training day. Not a per-drink multiplier.
    static let pointsPerScoredPint = 12.0
    static let metersPerKilometer = 1000.0

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

    static func beerPoints(scoredPintDays: Int) -> Double {
        Double(max(0, scoredPintDays)) * pointsPerScoredPint
    }

    static func totalIndex(
        swimMeters: Double,
        runMeters: Double,
        rideMeters: Double,
        scoredPintDays: Int
    ) -> Double {
        let training =
            trainingPoints(meters: swimMeters, sport: .swim)
            + trainingPoints(meters: runMeters, sport: .run)
            + trainingPoints(meters: rideMeters, sport: .ride)
        return training + beerPoints(scoredPintDays: scoredPintDays)
    }
}
