import Foundation

/// Pure rules for the nearby pint ping. No MapKit, location managers, or notifications.
enum VenuePingPlanner: Sendable {
    static let windowStartHour = 18
    static let windowEndHour = 2
    static let poiRadiusMeters = 80.0
    /// Inside this radius the user is treated as home or work, even if a bar is next door.
    static let definitePlaceMeters = 80.0
    /// Pins farther than this are ignored so a saved office does not suppress a real pub.
    static let considerPlaceMeters = 150.0
    static let maxVisitAccuracyMeters = 150.0

    struct Coordinate: Equatable, Sendable {
        var latitude: Double
        var longitude: Double
    }

    struct VisitSnapshot: Equatable, Sendable {
        var coordinate: Coordinate
        var arrivalDate: Date
        var horizontalAccuracy: Double
        var isPrecise: Bool
        var isArrival: Bool
    }

    struct NearbyPOI: Equatable, Sendable {
        var name: String
        var coordinate: Coordinate
        var distanceMeters: Double
    }

    enum SkipReason: Equatable, Sendable {
        case disabled
        case notArrival
        case notPrecise
        case poorAccuracy
        case outsideWindow
        case alreadyLoggedToday
        case alreadyPingedToday
        case atHome
        case atWork
        case noMatchingPOI
    }

    enum Decision: Equatable, Sendable {
        case skip(SkipReason)
        /// Cheap gates passed; caller must look up a nearby drink POI and call again.
        case needsPOILookup
        case ping(placeName: String)
    }

    static func decide(
        enabled: Bool,
        visit: VisitSnapshot,
        home: Coordinate?,
        work: Coordinate?,
        nearbyPOI: NearbyPOI?,
        didLookupPOI: Bool,
        lastBeerLoggedAt: Date?,
        lastPingAt: Date?,
        calendar: Calendar = .current
    ) -> Decision {
        guard enabled else { return .skip(.disabled) }
        guard visit.isArrival, visit.arrivalDate != .distantPast else {
            return .skip(.notArrival)
        }
        guard visit.isPrecise else { return .skip(.notPrecise) }
        guard visit.horizontalAccuracy > 0, visit.horizontalAccuracy <= maxVisitAccuracyMeters else {
            return .skip(.poorAccuracy)
        }
        guard isInWindow(visit.arrivalDate, calendar: calendar) else {
            return .skip(.outsideWindow)
        }
        if let lastBeerLoggedAt, calendar.isDate(lastBeerLoggedAt, inSameDayAs: visit.arrivalDate) {
            return .skip(.alreadyLoggedToday)
        }
        if let lastPingAt, calendar.isDate(lastPingAt, inSameDayAs: visit.arrivalDate) {
            return .skip(.alreadyPingedToday)
        }

        let homeExclusion = exclusion(place: home, user: visit.coordinate)
        let workExclusion = exclusion(place: work, user: visit.coordinate)
        if case .definite = homeExclusion { return .skip(.atHome) }
        if case .definite = workExclusion { return .skip(.atWork) }
        if didLookupPOI == false { return .needsPOILookup }

        if blocks(homeExclusion, poi: nearbyPOI) { return .skip(.atHome) }
        if blocks(workExclusion, poi: nearbyPOI) { return .skip(.atWork) }

        guard let nearbyPOI, nearbyPOI.distanceMeters <= poiRadiusMeters, nearbyPOI.name.isEmpty == false else {
            return .skip(.noMatchingPOI)
        }
        return .ping(placeName: nearbyPOI.name)
    }

    static func isInWindow(_ date: Date, calendar: Calendar = .current) -> Bool {
        let hour = calendar.component(.hour, from: date)
        return hour >= windowStartHour || hour < windowEndHour
    }

    /// Haversine distance in meters. Used by tests to pick realistic offsets.
    static func distanceMeters(from a: Coordinate, to b: Coordinate) -> Double {
        let earth = 6_371_000.0
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let dLat = (b.latitude - a.latitude) * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let h = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * earth * asin(min(1, sqrt(h)))
    }

    private enum PlaceExclusion: Equatable {
        case definite
        case needsCloserPOI(placeDistance: Double)
        case none
    }

    private static func exclusion(place: Coordinate?, user: Coordinate) -> PlaceExclusion {
        guard let place else { return .none }
        let distance = distanceMeters(from: user, to: place)
        if distance < definitePlaceMeters { return .definite }
        if distance > considerPlaceMeters { return .none }
        return .needsCloserPOI(placeDistance: distance)
    }

    /// In the 80–150 m band, ping only when a matching POI is closer than the saved pin.
    private static func blocks(_ exclusion: PlaceExclusion, poi: NearbyPOI?) -> Bool {
        switch exclusion {
        case .none, .definite:
            return false
        case .needsCloserPOI(let placeDistance):
            guard let poi else { return true }
            return poi.distanceMeters >= placeDistance
        }
    }
}
