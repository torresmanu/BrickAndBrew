import Foundation

/// User-marked home and work. Coordinates stay on this iPhone.
struct SavedPlace: Codable, Equatable, Sendable {
    var latitude: Double
    var longitude: Double
    var label: String

    var coordinate: VenuePingPlanner.Coordinate {
        VenuePingPlanner.Coordinate(latitude: latitude, longitude: longitude)
    }
}

enum VenuePlaceKind: String, Sendable {
    case home
    case work
}

/// Nearby pint starts on. The user can turn it off in Me.
enum VenuePingSettings {
    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: ReminderDefaults.venueEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: ReminderDefaults.venueEnabledKey) }
    }
}

/// On-device home/work pins and daily pint-ping bookkeeping. Never CloudKit.
enum VenuePlaceStore {
    private static let homeKey = "venuePing.home"
    private static let workKey = "venuePing.work"
    private static let lastBeerKey = "venuePing.lastBeerLoggedAt"
    private static let lastPingKey = "venuePing.lastPingAt"

    static var home: SavedPlace? {
        get { decode(key: homeKey) }
        set { encode(newValue, key: homeKey) }
    }

    static var work: SavedPlace? {
        get { decode(key: workKey) }
        set { encode(newValue, key: workKey) }
    }

    static var lastBeerLoggedAt: Date? {
        get { UserDefaults.standard.object(forKey: lastBeerKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastBeerKey) }
    }

    static var lastPingAt: Date? {
        get { UserDefaults.standard.object(forKey: lastPingKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastPingKey) }
    }

    static func place(_ kind: VenuePlaceKind) -> SavedPlace? {
        switch kind {
        case .home: home
        case .work: work
        }
    }

    static func setPlace(_ place: SavedPlace?, kind: VenuePlaceKind) {
        switch kind {
        case .home: home = place
        case .work: work = place
        }
    }

    static func markBeerLogged(at date: Date = Date()) {
        lastBeerLoggedAt = date
    }

    static func markPinged(at date: Date = Date()) {
        lastPingAt = date
    }

    /// Sign out and account deletion wipe local pins so the next user starts clean.
    static func clearAll() {
        home = nil
        work = nil
        lastBeerLoggedAt = nil
        lastPingAt = nil
    }

    private static func decode(key: String) -> SavedPlace? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SavedPlace.self, from: data)
    }

    private static func encode(_ place: SavedPlace?, key: String) {
        if let place, let data = try? JSONEncoder().encode(place) {
            UserDefaults.standard.set(data, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
