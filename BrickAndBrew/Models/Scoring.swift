import Foundation

/// Single place for the Total Index weights so boards stay consistent.
enum Scoring: Sendable {
    static let swimPointsPerKilometer = 10.0
    static let runPointsPerKilometer = 3.0
    static let ridePointsPerKilometer = 1.0
    static let pointsPerBeer = 2.0
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

    static func beerPoints(count: Int) -> Double {
        Double(max(0, count)) * pointsPerBeer
    }
}
