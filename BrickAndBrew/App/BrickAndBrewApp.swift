import SwiftUI
import UserNotifications

@main
struct BrickAndBrewApp: App {
    @State private var session = AppSession()

    init() {
        ReminderDefaults.prepareFirstRun()
        BrandChrome.apply()
        if LaunchEnvironment.isRunningUnitTests == false {
            UNUserNotificationCenter.current().delegate = VenueNotificationCenterDelegate.shared
            VenueVisitMonitor.shared.prepare()
            cancelRetiredPintReminder()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .preferredColorScheme(.dark)
                .tint(Palette.accent)
                .task {
                    guard LaunchEnvironment.isRunningUnitTests == false else { return }
                    await session.bootstrap()
                }
        }
    }
}

/// Drops the 7:00 pm pint reminder scheduled by older builds. Nearby pint uses a different identifier.
private func cancelRetiredPintReminder() {
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: ["pint.atRisk"])
    center.removeDeliveredNotifications(withIdentifiers: ["pint.atRisk"])
}
