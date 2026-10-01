import SwiftUI
import UserNotifications

@main
struct BrickAndBrewApp: App {
    @State private var session = AppSession()

    init() {
        BrandChrome.apply()
        if LaunchEnvironment.isRunningUnitTests == false {
            cancelRetiredDrinkNudges()
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

/// Drops pint reminders and bar-location prompts scheduled by older builds.
private func cancelRetiredDrinkNudges() {
    let identifiers = ["pint.atRisk", "pint.venue"]
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: identifiers)
    center.removeDeliveredNotifications(withIdentifiers: identifiers)
}
