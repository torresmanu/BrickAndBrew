import Foundation
import UserNotifications

/// One-shot local ping when a visit looks like a drink venue. Not a server push.
enum VenuePingScheduler {
    static let identifier = "pint.venue"

    static func requestAuthorization() async -> Bool {
        guard LaunchEnvironment.isRunningUnitTests == false else { return false }
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    static func notify(placeName: String) async {
        guard LaunchEnvironment.isRunningUnitTests == false else { return }
        let content = UNMutableNotificationContent()
        content.title = VenuePingCopy.notificationTitle
        content.body = VenuePingCopy.notificationBody(placeName: placeName)
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    static func cancel() {
        guard LaunchEnvironment.isRunningUnitTests == false else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }
}
