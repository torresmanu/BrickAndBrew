import Foundation
import UserNotifications

/// Debug-only path so a simulator recording can open the real crew UI.
/// Release builds ignore the launch argument.
enum ReviewRecording {
    static let argument = "-ReviewRecording"

    static var isEnabled: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains(argument)
        #else
        false
        #endif
    }

    static let teamId = "team-brick"
    static let currentUserId = "nico"

    @MainActor
    static func install(into session: AppSession) {
        let team = Team(
            id: teamId,
            inviteCode: "BRICK",
            name: "Brick",
            seasonStart: daysAgo(40)
        )
        session.profile = Profile(
            id: currentUserId,
            appleUserId: "review-nico",
            displayName: "Nico",
            teamId: teamId,
            stravaAthleteId: 9_001,
            stravaAthleteName: "Nico"
        )
        session.team = team
        session.selectedTab = .crew
        ReminderDefaults.didPromptFirstRun = false
        ReminderDefaults.prepareFirstRun()
        VenuePingSettings.isEnabled = true
        VenuePlaceStore.setPlace(
            SavedPlace(latitude: 41.387, longitude: 2.170, label: "Carrer del Consell de Cent, 242"),
            kind: .home
        )
        VenuePlaceStore.setPlace(
            SavedPlace(latitude: 41.395, longitude: 2.164, label: "Passeig de Gràcia, 92"),
            kind: .work
        )
        session.phase = .ready
    }

    /// Posted with the system, so it still appears after the app is backgrounded.
    static func schedulePing(after seconds: TimeInterval) async {
        let content = UNMutableNotificationContent()
        content.title = VenuePingCopy.notificationTitle
        content.body = VenuePingCopy.notificationBody(placeName: "The Half Mile")
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(
            identifier: VenuePingScheduler.identifier,
            content: content,
            trigger: trigger
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    static var profiles: [Profile] {
        [
            Profile(
                id: currentUserId,
                appleUserId: "review-nico",
                displayName: "Nico",
                teamId: teamId,
                stravaAthleteId: 9_001,
                stravaAthleteName: "Nico"
            ),
            Profile(id: "mara", appleUserId: "review-mara", displayName: "Mara", teamId: teamId),
            Profile(id: "jules", appleUserId: "review-jules", displayName: "Jules", teamId: teamId)
        ]
    }

    static var activities: [Activity] {
        [
            activity(
                id: "tri-swim",
                userId: currentUserId,
                sport: .swim,
                daysAgo: 1,
                hour: 7,
                minute: 5,
                meters: 1_500,
                moving: 28 * 60 + 12,
                polyline: PolylineCodec.sampleSwim
            ),
            activity(
                id: "tri-ride",
                userId: currentUserId,
                sport: .ride,
                daysAgo: 1,
                hour: 7,
                minute: 45,
                meters: 40_200,
                moving: 72 * 60 + 4,
                polyline: PolylineCodec.sampleBike
            ),
            activity(
                id: "tri-run",
                userId: currentUserId,
                sport: .run,
                daysAgo: 1,
                hour: 9,
                minute: 10,
                meters: 10_100,
                moving: 48 * 60 + 33,
                polyline: PolylineCodec.sampleRun
            ),
            activity(id: "a2", userId: currentUserId, sport: .ride, daysAgo: 0, meters: 42_000),
            activity(id: "a4", userId: "mara", sport: .swim, daysAgo: 0, meters: 3100),
            activity(id: "a5", userId: "jules", sport: .ride, daysAgo: 1, meters: 80_000)
        ]
    }

    static var beers: [Beer] {
        [
            Beer(id: "b1", userId: currentUserId, teamId: teamId, count: 2, loggedAt: daysAgo(1), note: "IPA"),
            Beer(id: "b2", userId: "mara", teamId: teamId, count: 1, loggedAt: daysAgo(0), note: nil),
            Beer(id: "b3", userId: "jules", teamId: teamId, count: 3, loggedAt: daysAgo(2), note: nil)
        ]
    }

    static func beers(for userId: String) -> [Beer] {
        beers.filter { $0.userId == userId }
    }

    private static func activity(
        id: String,
        userId: String,
        sport: SportKind,
        daysAgo: Int,
        meters: Double,
        hour: Int = 12,
        minute: Int = 0,
        moving: Int = 3_600,
        polyline: String? = nil
    ) -> Activity {
        Activity(
            id: id,
            stravaId: Int64(abs(id.hashValue)),
            userId: userId,
            teamId: teamId,
            type: sport.rawValue,
            sport: sport,
            startDate: date(daysAgo: daysAgo, hour: hour, minute: minute),
            distanceMeters: meters,
            movingTimeSeconds: moving,
            averageHeartrate: nil,
            maxHeartrate: nil,
            elevationGain: nil,
            summaryPolyline: polyline
        )
    }

    private static func date(daysAgo: Int, hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? day
    }

    private static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }
}
