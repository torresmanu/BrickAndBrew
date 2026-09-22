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

/// Shared keys so both reminders start on until the user turns one off.
enum ReminderDefaults {
    static let pintEnabledKey = "pintReminder.enabled"
    static let venueEnabledKey = "venuePing.enabled"
    private static let didPromptKey = "reminders.didPromptFirstRun"

    static func register() {
        UserDefaults.standard.register(defaults: [
            pintEnabledKey: true,
            venueEnabledKey: true
        ])
    }

    /// First crew-tab visit writes the on defaults and asks iOS for permission once.
    static var didPromptFirstRun: Bool {
        get { UserDefaults.standard.bool(forKey: didPromptKey) }
        set { UserDefaults.standard.set(newValue, forKey: didPromptKey) }
    }

    static func prepareFirstRun() {
        register()
        if didPromptFirstRun == false {
            PintReminderSettings.isEnabled = true
            VenuePingSettings.isEnabled = true
        }
    }

    static func resetForSignOut() {
        UserDefaults.standard.removeObject(forKey: pintEnabledKey)
        UserDefaults.standard.removeObject(forKey: venueEnabledKey)
        UserDefaults.standard.removeObject(forKey: didPromptKey)
    }
}

enum PintReminderSettings {
    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: ReminderDefaults.pintEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: ReminderDefaults.pintEnabledKey) }
    }
}
