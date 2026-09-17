import Foundation

/// Triathlon sports we score. Anything else from Strava is stored but worth 0.
enum SportKind: String, Codable, Sendable, CaseIterable {
    case swim
    case run
    case ride
    case other

    var title: String {
        switch self {
        case .swim: "Swim"
        case .run: "Run"
        case .ride: "Bike"
        case .other: "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .swim: "figure.pool.swim"
        case .run: "figure.run"
        case .ride: "figure.outdoor.cycle"
        case .other: "figure.mixed.cardio"
        }
    }
}
