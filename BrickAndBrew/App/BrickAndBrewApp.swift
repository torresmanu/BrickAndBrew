import SwiftUI
import UserNotifications

@main
struct BrickAndBrewApp: App {
    @State private var session = AppSession()

    init() {
        BrandChrome.apply()
        if LaunchEnvironment.isRunningUnitTests == false {
            UNUserNotificationCenter.current().delegate = PintReminderCenterDelegate.shared
            VenueVisitMonitor.shared.prepare()
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
