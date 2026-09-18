import Foundation

enum CrewCache {
    private static let key = "crew.snapshot"

    static func load() -> CrewSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(CrewSnapshot.self, from: data)
    }

    static func save(_ snapshot: CrewSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    static func updateDisplayName(userId: String, displayName: String) {
        guard var snapshot = load() else { return }
        snapshot.entries = snapshot.entries.map { entry in
            guard entry.userId == userId else { return entry }
            var next = entry
            next.displayName = displayName
            return next
        }
        save(snapshot)
    }
}

enum SyncCursor {
    private static let key = "strava.lastSyncAt"

    static func lastSyncAt() -> Date? {
        UserDefaults.standard.object(forKey: key) as? Date
    }

    static func setLastSyncAt(_ date: Date) {
        UserDefaults.standard.set(date, forKey: key)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

enum PintReminderSettings {
    private static let key = "pintReminder.enabled"

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
