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

/// Remembers a pint-notification tap until the crew tabs are foregrounded.
/// The notification callback is not the main actor; switching tabs there crashes.
@MainActor
enum LogTabOpenRequest {
    private(set) static var isPending = false

    static func arm() {
        isPending = true
        NotificationCenter.default.post(name: .openLogTab, object: nil)
    }

    static func consume() -> Bool {
        guard isPending else { return false }
        isPending = false
        return true
    }

    static func cancel() {
        isPending = false
    }
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
        let identifier = response.notification.request.identifier
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else { return }
        guard identifier == PintReminderPlanner.identifier || identifier == VenuePingScheduler.identifier else {
            return
        }
        // Location pings are delivered while this process is already awake in the
        // background. Updating SwiftUI from this callback redraws the tab bar off
        // the main thread and crashes. Arm the request on the next main-actor turn.
        Task { @MainActor in
            LogTabOpenRequest.arm()
        }
    }
}
