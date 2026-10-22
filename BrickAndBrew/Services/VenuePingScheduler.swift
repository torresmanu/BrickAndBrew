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

extension Notification.Name {
    static let openLogTab = Notification.Name("brickandbrew.openLogTab")
}

/// Remembers a nearby-pint tap until the crew tabs are foregrounded.
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

final class VenueNotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = VenueNotificationCenterDelegate()

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
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else { return }
        guard response.notification.request.identifier == VenuePingScheduler.identifier else { return }
        // Location pings arrive while the process is awake in the background.
        // Updating SwiftUI from this callback redraws the tab bar off the main thread.
        Task { @MainActor in
            LogTabOpenRequest.arm()
        }
    }
}
