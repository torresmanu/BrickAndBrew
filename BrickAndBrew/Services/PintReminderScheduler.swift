import Foundation
import UserNotifications

/// Schedules the one-shot 7:00 pm pint ping. Skipped in the unit-test host.
@MainActor
enum PintReminderScheduler {
    static func refresh(pint: Streak, now: Date = Date(), calendar: Calendar = .current) async {
        guard LaunchEnvironment.isRunningUnitTests == false else { return }

        let fire = PintReminderPlanner.nextFire(
            streak: pint,
            now: now,
            calendar: calendar,
            enabled: PintReminderSettings.isEnabled
        )
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [PintReminderPlanner.identifier])
        guard let fire else { return }

        let content = UNMutableNotificationContent()
        content.title = StreakCopy.pintReminderTitle
        content.body = StreakCopy.atRiskNudge(kind: .pint)
        content.sound = .default

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: PintReminderPlanner.identifier,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    static func cancel() {
        guard LaunchEnvironment.isRunningUnitTests == false else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [PintReminderPlanner.identifier]
        )
    }

    static func requestAuthorization() async -> Bool {
        guard LaunchEnvironment.isRunningUnitTests == false else { return false }
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }
}

extension Notification.Name {
    static let openLogTab = Notification.Name("brickandbrew.openLogTab")
}

final class PintReminderCenterDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = PintReminderCenterDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.notification.request.identifier == PintReminderPlanner.identifier else { return }
        NotificationCenter.default.post(name: .openLogTab, object: nil)
    }
}
